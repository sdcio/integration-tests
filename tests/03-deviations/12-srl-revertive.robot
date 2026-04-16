*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Library             RPA.JSON
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/gnmic.robot
Resource            ../Keywords/yq.robot
Resource            ../Keywords/intent-routing.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup

*** Variables ***
# sr1 = netconf ; sr2 = gNMI get

@{SDCIO_SRL_NODES}     srl1    srl2    srl3
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4    intent5
&{intents}        intent1=vrf1    intent2=vrf2    intent3=vrf3    intent4=vrf4    intent5=vrf5
&{intentsinterfaces}        intent1=ethernet-1/1    intent2=ethernet-1/2    intent3=ethernet-1/3    intent4=ethernet-1/4    intent5=ethernet-1/5
${retry}    2s
${eventual_timeout}    2min
${options}    --skip-verify -e PROTO
${optionsSet}    --skip-verify -e JSON_IETF
${VERIFY_IMMEDIATE_DEVICE_DELETE}    ${FALSE}
${INTENT_TARGET_CACHE}    ${None}


*** Test Cases ***
Delete SRL device config and Verify Revertive Deviations - intent1
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent1
    Run Delete And Verify Revertive For Intent    intent1

Delete SRL device config and Verify Revertive Deviations - intent2
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent2
    Run Delete And Verify Revertive For Intent    intent2

Delete SRL device config and Verify Revertive Deviations - intent3
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent3
    Run Delete And Verify Revertive For Intent    intent3

Delete SRL device config and Verify Revertive Deviations - intent4
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent4
    Run Delete And Verify Revertive For Intent    intent4

Delete SRL device config and Verify Revertive Deviations - intent5
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent5
    Run Delete And Verify Revertive For Intent    intent5

Delete ALL SRL device config and Verify Revertive Deviations
    [Documentation]    Delete device config and Verify Revertive Deviations on Config(Set) -- multiple intents at once
    Delete All Device Config
    Verify All Intents Are Reverted

Adjust SRL device config and Verify Revertive Deviations - intent1
    [Documentation]    Adjust SRL config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent1
    Run Adjust And Verify Revertive For Intent    intent1

Adjust SRL device config and Verify Revertive Deviations - intent2
    [Documentation]    Adjust SRL config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent2
    Run Adjust And Verify Revertive For Intent    intent2

Adjust SRL device config and Verify Revertive Deviations - intent3
    [Documentation]    Adjust SRL config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent3
    Run Adjust And Verify Revertive For Intent    intent3

Adjust SRL device config and Verify Revertive Deviations - intent4
    [Documentation]    Adjust SRL config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent4
    Run Adjust And Verify Revertive For Intent    intent4

Adjust SRL device config and Verify Revertive Deviations - intent5
    [Documentation]    Adjust SRL config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent5
    Run Adjust And Verify Revertive For Intent    intent5

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds    15min    ${retry}    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    Initialize Intent Target Cache    ${CURDIR}/input/srl    -srl

Run Delete And Verify Revertive For Intent
    [Arguments]    ${intent}
    Delete Device Config For Intent    ${intent}
    Verify Intent Is Reverted    ${intent}

Run Adjust And Verify Revertive For Intent
    [Arguments]    ${intent}
    Adjust Device Config For Intent    ${intent}
    Verify Intent Is Reverted    ${intent}

Delete Device Config For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Log    Deleting config for intent ${intent} on ${node}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=${intents.${intent}}]"
        Run Keyword If    ${VERIFY_IMMEDIATE_DEVICE_DELETE}
        ...    Verify Intent Config Is Deleted On Node
        ...    ${intent}
        ...    ${node}
    END

Verify Intent Config Is Deleted On Node
    [Arguments]    ${intent}    ${node}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/network-instance[name=${intents.${intent}}]"
    Should Be Empty    ${output}

Adjust Device Config For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Log    Adjusting config for intent ${intent} on ${node}
        Set Config on node via file
        ...    ${node}
        ...    ${optionsSet}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/"
        ...    ${CURDIR}/input/srl/deviations-${intent}.json
    END

Verify Intent Is Reverted
    [Arguments]    ${intent}
    @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Get Config from node and Verify Intent
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=${intents.${intent}}]" --path "/interface[name=${intentsinterfaces.${intent}}]"
        ...    ${expectedoutput}
    END

Delete All Device Config
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Log    Deleting all vrf config on ${node}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=vrf*]"
        Run Keyword If    ${VERIFY_IMMEDIATE_DEVICE_DELETE}
        ...    Verify All Intent Config Is Deleted On Node
        ...    ${node}
    END

Verify All Intent Config Is Deleted On Node
    [Arguments]    ${node}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/network-instance[name=vrf*]"
    Should Be Empty    ${output}

Verify All Intents Are Reverted
    @{all_intents} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}
    FOR    ${intent}    IN    @{all_intents}
        Verify Intent Is Reverted    ${intent}
    END

Cleanup
    Run    echo 'cleanup executed'
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-srl
    END
    Run Keyword If Any Tests Failed     DeleteAll

DeleteAll
    Log    Deleting all SRL Config
    FOR  ${node}    IN    @{SDCIO_SRL_NODES}
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
