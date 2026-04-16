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
&{replaceintents}             intent1=vrf11    intent2=vrf12    intent3=vrf13    intent4=vrf14    intent5=vrf15
&{intentsinterfaces}          intent1=ethernet-1/1    intent2=ethernet-1/2    intent3=ethernet-1/3    intent4=ethernet-1/4    intent5=ethernet-1/5
${options}                    --skip-verify -e PROTO
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

Update And Verify intent5
    [Tags]    update
    Update And Verify Intent    intent5

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

Replace And Verify intent5
    [Tags]    replace
    Replace And Verify Intent    intent5

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    Initialize Intent Target Cache    ${CURDIR}/input/srl    -srl

Cleanup
    Run    echo 'cleanup executed'
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-srl
    END
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
    [Arguments]    ${intent}    ${node}    ${vrf_name}    ${expected_file}
    @{expectedoutput} =    Load JSON from file    ${expected_file}
    ${compare} =    Get Config from node and Verify Intent
    ...    ${node}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/network-instance[name=${vrf_name}]" --path "/interface[name=${intentsinterfaces.${intent}}]"
    ...    ${expectedoutput}
    Should Be True    ${compare}

Verify Intent Config Deleted On Node
    [Arguments]    ${intent}    ${node}    ${vrf_name}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/network-instance[name=${vrf_name}]"
    Should Be Empty    ${output}

Update And Verify Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    -update    ${CURDIR}/input/srl    -srl
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node    ${intent}    ${node}
        ...    ${intents.${intent}}    ${CURDIR}/expectedoutput/srl/${intent}-srl-update.json
    END

Replace And Verify Intent
    [Arguments]    ${intent}
    Apply Intent On K8s    ${intent}    -replace    ${CURDIR}/input/srl    -srl
    @{nodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{nodes}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config On Node    ${intent}    ${node}
        ...    ${replaceintents.${intent}}    ${CURDIR}/expectedoutput/srl/${intent}-srl-replace.json
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Verify Intent Config Deleted On Node    ${intent}    ${node}    ${intents.${intent}}
    END

