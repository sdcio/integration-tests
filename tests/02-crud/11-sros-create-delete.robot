*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Library             RPA.JSON
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/yq.robot
Resource            ../Keywords/gnmic.robot
Resource            ../Keywords/intent-routing.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup

*** Variables ***
# sr1 = netconf ; sr2 = gNMI get

@{SDCIO_SROS_NODES}           sr1    sr2
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}       intent3    intent4
&{intents}                    intent1=vprn123    intent2=vprn234    intent3=vprn789    intent4=vprn987
${options}                    --insecure -e JSON
${filter}                     "configure/service/vprn"
${eventual_timeout}           2min
${retry}                      2s
${orphan_reconcile_grace}     30s
${INTENT_TARGET_CACHE}        ${None}    # populated by Initialize Intent Target Cache in Setup

*** Test Cases ***
Create And Verify intent1
    [Tags]    create
    Create And Verify Intent    intent1

Create And Verify intent2
    [Tags]    create
    Create And Verify Intent    intent2

Create And Verify intent3
    [Tags]    create
    Create And Verify Intent    intent3

Create And Verify intent4
    [Tags]    create
    Create And Verify Intent    intent4

Delete And Verify intent1
    [Tags]    delete
    Delete And Verify Intent    intent1

Delete And Verify intent2
    [Tags]    delete
    Delete And Verify Intent    intent2

Delete And Verify intent3
    [Tags]    delete
    Delete And Verify Intent    intent3

Delete And Verify intent4
    [Tags]    delete
    Delete And Verify Intent    intent4

Delete Config Intent with orphan policy keeps device config - intent3
    [Tags]    orphan    delete    config
    Verify Orphan Deletion Policy For Intent    intent3

Delete ConfigSet with orphan policy keeps device config on all targets - intent1
    [Tags]    orphan    delete    configset
    Verify Orphan Deletion Policy For ConfigSet    intent1

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    Initialize Intent Target Cache    ${CURDIR}/input/sros    -sros

Cleanup
    Run    echo 'cleanup executed'
    Run Keyword If Any Tests Failed     DeleteAll
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "customer"

DeleteAll
    Log    Deleting all SROS Config
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=*]"
    END

Verify Intent Config On Node
    [Arguments]    ${intent}    ${node}    ${expected_file}
    @{expectedoutput} =    Load JSON from file    ${expected_file}
    ${compare} =    Get Config from node and Verify Intent
    ...    ${node}
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
    ...    ${expectedoutput}
    ...    ${filter}
    Should Be True    ${compare}

Verify Intent Config Deleted On Node
    [Arguments]    ${intent}    ${node}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
    ...    ${filter}
    ${output} =    Evaluate    [i for i in ${output} if i]
    Should Be Empty    ${output}

Create And Verify Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    ${EMPTY}    ${CURDIR}/input/sros    -sros
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{nodes}
        Verify Intent Config On Node    ${intent}    ${node}    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
    END

Delete And Verify Intent
    [Arguments]    ${intent}
    Delete Intent From K8s    ${intent}    -sros
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}
    END

Verify Orphan Deletion Policy For Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    ${EMPTY}    ${CURDIR}/input/sros    -sros
    kubectl patch    config    ${intent}-sros    '{"spec": {"lifecycle": {"deletionPolicy": "orphan"}}}'
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    ${intent}-sros
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{nodes}
        Verify Intent Config On Node    ${intent}    ${node}    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
    END
    Delete Intent From K8s    ${intent}    -sros
    Sleep    ${orphan_reconcile_grace}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node
        ...    ${intent}
        ...    ${node}
        ...    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
    END
    FOR    ${node}    IN    @{nodes}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}
    END

Verify Orphan Deletion Policy For ConfigSet
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    ${EMPTY}    ${CURDIR}/input/sros    -sros
    kubectl patch    configset    ${intent}-sros    '{"spec": {"lifecycle": {"deletionPolicy": "orphan"}}}'
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    ${intent}-sros
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{nodes}
        Verify Intent Config On Node    ${intent}    ${node}    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
    END
    Delete Intent From K8s    ${intent}    -sros
    Sleep    ${orphan_reconcile_grace}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node
        ...    ${intent}
        ...    ${node}
        ...    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
    END
    FOR    ${node}    IN    @{nodes}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}
    END
