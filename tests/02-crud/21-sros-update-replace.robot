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
&{replaceintents}             intent1=vprn1123    intent2=vprn1234    intent3=vprn1789    intent4=vprn1987
${options}                    --insecure -e JSON
${filter}                     "configure/service/vprn"
${eventual_timeout}           2min
${retry}                      2s
${INTENT_TARGET_CACHE}        ${None}    # populated by Initialize Intent Target Cache in Setup

*** Test Cases ***
Update And Verify intent1
    [Tags]    update
    Update And Verify Intent    intent1

Update And Verify intent2
    [Tags]    update
    Update And Verify Intent    intent2

Update And Verify intent3
    [Tags]    update
    Update And Verify Intent    intent3

Update And Verify intent4
    [Tags]    update
    Update And Verify Intent    intent4

Replace And Verify intent1
    [Tags]    replace
    Replace And Verify Intent    intent1

Replace And Verify intent2
    [Tags]    replace
    Replace And Verify Intent    intent2

Replace And Verify intent3
    [Tags]    replace
    Replace And Verify Intent    intent3

Replace And Verify intent4
    [Tags]    replace
    Replace And Verify Intent    intent4

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    Initialize Intent Target Cache    ${CURDIR}/input/sros    -sros

Cleanup
    Run    echo 'cleanup executed'
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-sros
    END
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
    [Arguments]    ${intent}    ${node}    ${vprn_name}    ${expected_file}
    @{expectedoutput} =    Load JSON from file    ${expected_file}
    ${compare} =    Get Config from node and Verify Intent
    ...    ${node}
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=${vprn_name}]"
    ...    ${expectedoutput}
    ...    ${filter}
    Should Be True    ${compare}

Verify Intent Config Deleted On Node
    [Arguments]    ${intent}    ${node}    ${vprn_name}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=${vprn_name}]"
    ...    ${filter}
    ${output} =    Evaluate    [i for i in ${output} if i]
    Should Be Empty    ${output}

Update And Verify Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    -update    ${CURDIR}/input/sros    -sros
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node    ${intent}    ${node}
        ...    ${intents.${intent}}    ${CURDIR}/expectedoutput/sros/${intent}-sros-update.json
    END

Replace And Verify Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    -replace    ${CURDIR}/input/sros    -sros
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node    ${intent}    ${node}
        ...    ${replaceintents.${intent}}    ${CURDIR}/expectedoutput/sros/${intent}-sros-replace.json
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}    ${intents.${intent}}
    END

