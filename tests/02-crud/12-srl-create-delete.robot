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
@{SDCIO_SRL_NODES}            srl1    srl2    srl3
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}       intent3    intent4    intent5
&{intents}                    intent1=vrf1    intent2=vrf2    intent3=vrf3    intent4=vrf4    intent5=vrf5
&{intentsinterfaces}          intent1=ethernet-1/1    intent2=ethernet-1/2    intent3=ethernet-1/3    intent4=ethernet-1/4    intent5=ethernet-1/5
${options}                    --skip-verify -e PROTO
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

Create And Verify intent5
    [Tags]    create
    Create And Verify Intent    intent5

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

Delete And Verify intent5
    [Tags]    delete
    Delete And Verify Intent    intent5

Delete Config Intent with orphan policy keeps device config - intent3
    [Tags]    orphan    delete    config
    Verify Orphan Deletion Policy For Intent    intent3

Delete ConfigSet with orphan policy keeps device config on all targets - intent1
    [Tags]    orphan    delete    configset
    Verify Orphan Deletion Policy For ConfigSet    intent1

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    Initialize Intent Target Cache    ${CURDIR}/input/srl    -srl

Cleanup
    Run    echo 'cleanup executed'
    Run Keyword If Any Tests Failed     DeleteAll

DeleteAll
    Log    Deleting all SRL Config
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Delete Config from node
        ...    ${node}
        ...    --skip-verify -e PROTO
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=vrf*]"
        Delete Config from node
        ...    ${node}
        ...    --skip-verify -e PROTO
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/interface[name=ethernet-1/*]"
    END

Verify Intent Config On Node
    [Arguments]    ${intent}    ${node}    ${expected_file}
    @{expectedoutput} =    Load JSON from file    ${expected_file}
    ${compare} =    Get Config from node and Verify Intent
    ...    ${node}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/network-instance[name=${intents.${intent}}]" --path "/interface[name=${intentsinterfaces.${intent}}]"
    ...    ${expectedoutput}
    Should Be True    ${compare}

Verify Intent Config Deleted On Node
    [Arguments]    ${intent}    ${node}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/network-instance[name=${intents.${intent}}]" --path "/interface[name=${intentsinterfaces.${intent}}]"
    Should Be Empty    ${output}

Create And Verify Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    ${EMPTY}    ${CURDIR}/input/srl    -srl
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{nodes}
        Verify Intent Config On Node    ${intent}    ${node}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
    END

Delete And Verify Intent
    [Arguments]    ${intent}
    Delete Intent From K8s    ${intent}    -srl
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}
    END

Verify Orphan Deletion Policy For Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    ${EMPTY}    ${CURDIR}/input/srl    -srl
    kubectl patch    config    ${intent}-srl    '{"spec": {"lifecycle": {"deletionPolicy": "orphan"}}}'
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    ${intent}-srl
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{nodes}
        Verify Intent Config On Node    ${intent}    ${node}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
    END
    Delete Intent From K8s    ${intent}    -srl
    Sleep    ${orphan_reconcile_grace}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node
        ...    ${intent}
        ...    ${node}
        ...    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
    END
    FOR    ${node}    IN    @{nodes}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=${intents.${intent}}]"
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/interface[name=${intentsinterfaces.${intent}}]"
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}
    END

Verify Orphan Deletion Policy For ConfigSet
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    ${EMPTY}    ${CURDIR}/input/srl    -srl
    kubectl patch    configset    ${intent}-srl    '{"spec": {"lifecycle": {"deletionPolicy": "orphan"}}}'
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    ${intent}-srl
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{nodes}
        Verify Intent Config On Node    ${intent}    ${node}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
    END
    Delete Intent From K8s    ${intent}    -srl
    Sleep    ${orphan_reconcile_grace}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node
        ...    ${intent}
        ...    ${node}
        ...    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
    END
    FOR    ${node}    IN    @{nodes}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=${intents.${intent}}]"
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/interface[name=${intentsinterfaces.${intent}}]"
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}
    END