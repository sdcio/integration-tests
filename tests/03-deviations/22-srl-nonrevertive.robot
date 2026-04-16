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
Resource            ../Keywords/deviation.robot
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
${eventual_timeout}    65sec
${options}    --skip-verify -e PROTO
${optionsSet}    --skip-verify -e JSON_IETF
${VERIFY_DEVICE_CONFIG_ON_FULL_ACCEPT}    ${FALSE}
${INTENT_TARGET_CACHE}    ${None}

*** Test Cases ***
Create Deviations and Verify non-revertive behavior - intent1
    [Documentation]    Create deviations and verify non-revertive behavior for a single intent.
    [Tags]    nonrevertive    create    verify    intent1
    Run Non-Revertive Scenario For Intent    intent1

Create Deviations and Verify non-revertive behavior - intent2
    [Documentation]    Create deviations and verify non-revertive behavior for a single intent.
    [Tags]    nonrevertive    create    verify    intent2
    Run Non-Revertive Scenario For Intent    intent2

Create Deviations and Verify non-revertive behavior - intent3
    [Documentation]    Create deviations and verify non-revertive behavior for a single intent.
    [Tags]    nonrevertive    create    verify    intent3
    Run Non-Revertive Scenario For Intent    intent3

Create Deviations and Verify non-revertive behavior - intent4
    [Documentation]    Create deviations and verify non-revertive behavior for a single intent.
    [Tags]    nonrevertive    create    verify    intent4
    Run Non-Revertive Scenario For Intent    intent4

Create Deviations and Verify non-revertive behavior - intent5
    [Documentation]    Create deviations and verify non-revertive behavior for a single intent.
    [Tags]    nonrevertive    create    verify    intent5
    Run Non-Revertive Scenario For Intent    intent5

Reject Deviations and Verify revertive behavior - intent1
    [Documentation]    Create deviations, reject them, and verify revertive behavior for a single intent.
    [Tags]    revertive    reject    verify    intent1
    Run Revertive Scenario For Intent    intent1

Reject Deviations and Verify revertive behavior - intent2
    [Documentation]    Create deviations, reject them, and verify revertive behavior for a single intent.
    [Tags]    revertive    reject    verify    intent2
    Run Revertive Scenario For Intent    intent2

Reject Deviations and Verify revertive behavior - intent3
    [Documentation]    Create deviations, reject them, and verify revertive behavior for a single intent.
    [Tags]    revertive    reject    verify    intent3
    Run Revertive Scenario For Intent    intent3

Reject Deviations and Verify revertive behavior - intent4
    [Documentation]    Create deviations, reject them, and verify revertive behavior for a single intent.
    [Tags]    revertive    reject    verify    intent4
    Run Revertive Scenario For Intent    intent4

Reject Deviations and Verify revertive behavior - intent5
    [Documentation]    Create deviations, reject them, and verify revertive behavior for a single intent.
    [Tags]    revertive    reject    verify    intent5
    Run Revertive Scenario For Intent    intent5

Create Deviations, Partially accept and Verify, Fully accept and Verify - intent1
    [Documentation]    Create deviations, partially accept, then fully accept and verify for a single intent.
    [Tags]    partial-accept    full-accept    verify    intent1
    Run Partial And Full Accept Scenario For Intent    intent1

Create Deviations, Partially accept and Verify, Fully accept and Verify - intent2
    [Documentation]    Create deviations, partially accept, then fully accept and verify for a single intent.
    [Tags]    partial-accept    full-accept    verify    intent2
    Run Partial And Full Accept Scenario For Intent    intent2

Create Deviations, Partially accept and Verify, Fully accept and Verify - intent3
    [Documentation]    Create deviations, partially accept, then fully accept and verify for a single intent.
    [Tags]    partial-accept    full-accept    verify    intent3
    Run Partial And Full Accept Scenario For Intent    intent3

Create Deviations, Partially accept and Verify, Fully accept and Verify - intent4
    [Documentation]    Create deviations, partially accept, then fully accept and verify for a single intent.
    [Tags]    partial-accept    full-accept    verify    intent4
    Run Partial And Full Accept Scenario For Intent    intent4

Create Deviations, Partially accept and Verify, Fully accept and Verify - intent5
    [Documentation]    Create deviations, partially accept, then fully accept and verify for a single intent.
    [Tags]    partial-accept    full-accept    verify    intent5
    Run Partial And Full Accept Scenario For Intent    intent5

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent1
    [Documentation]    Create deviations, partially revert by interface filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent1
    Run Partial Revert Scenario For Intent    intent1

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent2
    [Documentation]    Create deviations, partially revert by interface filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent2
    Run Partial Revert Scenario For Intent    intent2

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent3
    [Documentation]    Create deviations, partially revert by interface filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent3
    Run Partial Revert Scenario For Intent    intent3

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent4
    [Documentation]    Create deviations, partially revert by interface filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent4
    Run Partial Revert Scenario For Intent    intent4

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent5
    [Documentation]    Create deviations, partially revert by interface filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent5
    Run Partial Revert Scenario For Intent    intent5

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds    15min    ${retry}    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        # kubectl get     config ${intent}-srl
        kubectl patch    configset    ${intent}-srl    '{"spec": {"revertive": false}}'
        # kubectl get     config ${intent}-srl
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        kubectl get     config ${intent}-srl
        kubectl patch    config    ${intent}-srl    '{"spec": {"revertive": false}}'
        kubectl get     config ${intent}-srl
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
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

Run Non-Revertive Scenario For Intent
    [Arguments]    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    6
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/srl/${intent}-srl-nonrevertive.json

Run Revertive Scenario For Intent
    [Arguments]    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    6
    Reject Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    0
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

Run Partial And Full Accept Scenario For Intent
    [Arguments]    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    6
    kubectl apply    ${CURDIR}/input/srl/${intent}-srl-nonrevertive-partial.yaml
    Verify Deviation Count For Intent    ${intent}    3
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/srl/${intent}-srl-nonrevertive.json
    kubectl apply    ${CURDIR}/input/srl/${intent}-srl-nonrevertive-full.yaml
    Verify Deviation Count For Intent    ${intent}    0
    Run Keyword If    ${VERIFY_DEVICE_CONFIG_ON_FULL_ACCEPT}
    ...    Verify Device Config For Intent
    ...    ${intent}
    ...    ${CURDIR}/expectedoutput/srl/${intent}-srl-nonrevertive.json

Run Partial Revert Scenario For Intent
    [Arguments]    ${intent}
    Reset Intent Baseline For Intent    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    6
    Partial Revert Deviations For Intent by Interface    ${intent}

Reset Intent Baseline For Intent
    [Arguments]    ${intent}
    kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
    ${is_configset} =    Run Keyword And Return Status
    ...    List Should Contain Value
    ...    ${SDCIO_CONFIGSET_INTENTS}
    ...    ${intent}
    IF    ${is_configset}
        kubectl patch    configset    ${intent}-srl    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            Wait Until Keyword Succeeds
            ...    ${eventual_timeout}
            ...    ${retry}
            ...    Config Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-srl-${node}
        END
    ELSE
        kubectl patch    config    ${intent}-srl    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

Create Deviations For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Log    Creating Deviations on ${node} for intent ${intent}
        Set Config on node via file
        ...    ${node}
        ...    ${optionsSet}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/"
        ...    ${CURDIR}/input/srl/deviations-${intent}.json
    END

Reject Deviations For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{targetnodes}
        ${deviation_name} =    Get Deviation Name    ${intent}    ${node}
        Delete Deviation    ${deviation_name}
    END

Verify Deviation Count For Intent
    [Arguments]    ${intent}    ${expected_count}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    FOR    ${node}    IN    @{targetnodes}
        ${deviation_name} =    Get Deviation Name    ${intent}    ${node}
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Verify Deviation on k8s
        ...    ${deviation_name}
        ...    ${expected_count}
    END

Verify Device Config For Intent
    [Arguments]    ${intent}    ${expected_output_file}
    @{expectedoutput} =    Load JSON from file    ${expected_output_file}
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

Partial Revert Deviations For Intent by Interface
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SRL_NODES}
    ${targetnode} =    Get From List    ${targetnodes}    0
    ${deviation_name} =    Get Deviation Name    ${intent}    ${targetnode}
    ${interface_path} =    Set Variable    /interface[name=${intentsinterfaces.${intent}}]
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc deviation --deviation ${deviation_name} --filter-path ${interface_path} --revert
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Verify Deviation on k8s
    ...    ${deviation_name}
    ...    3

Get Deviation Name
    [Arguments]    ${intent}    ${node}
    ${is_configset} =    Run Keyword And Return Status
    ...    List Should Contain Value
    ...    ${SDCIO_CONFIGSET_INTENTS}
    ...    ${intent}
    IF    ${is_configset}
        RETURN    ${intent}-srl-${node}
    END
    RETURN    ${intent}-srl