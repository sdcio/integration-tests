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

@{SDCIO_SROS_NODES}     sr1    sr2
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4
&{intents}        intent1=vprn123    intent2=vprn234    intent3=vprn789    intent4=vprn987
${options}    --insecure -e JSON
${filter}    "configure/service/vprn"
${retry}    2s
${eventual_timeout}    65s
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

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent1
    [Documentation]    Create deviations, partially revert by admin-state filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent1
    Run Partial Revert Scenario For Intent    intent1

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent2
    [Documentation]    Create deviations, partially revert by admin-state filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent2
    Run Partial Revert Scenario For Intent    intent2

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent3
    [Documentation]    Create deviations, partially revert by admin-state filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent3
    Run Partial Revert Scenario For Intent    intent3

Partially Revert Deviations by Filter Path and Verify remaining deviations - intent4
    [Documentation]    Create deviations, partially revert by admin-state filter-path, and verify remaining deviations.
    [Tags]    partial-revert    filter-path    verify    intent4
    Run Partial Revert Scenario For Intent    intent4

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    customer
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        kubectl patch    configset    ${intent}-sros    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        kubectl patch    config    ${intent}-sros    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
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
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-sros
    END
    Run Keyword If Any Tests Failed     DeleteAll
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    customer

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

Run Non-Revertive Scenario For Intent
    [Arguments]    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    3
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/sros/${intent}-sros-nonrevertive.json

Run Revertive Scenario For Intent
    [Arguments]    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    3
    Reject Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    0
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/sros/${intent}-sros.json

Run Partial And Full Accept Scenario For Intent
    [Arguments]    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    3
    kubectl apply    ${CURDIR}/input/sros/${intent}-sros-nonrevertive-partial.yaml
    Verify Deviation Count For Intent    ${intent}    2
    Verify Device Config For Intent    ${intent}    ${CURDIR}/expectedoutput/sros/${intent}-sros-nonrevertive.json
    kubectl apply    ${CURDIR}/input/sros/${intent}-sros-nonrevertive-full.yaml
    Verify Deviation Count For Intent    ${intent}    0
    Run Keyword If    ${VERIFY_DEVICE_CONFIG_ON_FULL_ACCEPT}
    ...    Verify Device Config For Intent
    ...    ${intent}
    ...    ${CURDIR}/expectedoutput/sros/${intent}-sros-nonrevertive.json

Run Partial Revert Scenario For Intent
    [Arguments]    ${intent}
    Reset Intent Baseline For Intent    ${intent}
    Create Deviations For Intent    ${intent}
    Verify Deviation Count For Intent    ${intent}    3
    Partial Revert Deviations For Intent by Admin State    ${intent}

Reset Intent Baseline For Intent
    [Arguments]    ${intent}
    kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
    ${is_configset} =    Run Keyword And Return Status
    ...    List Should Contain Value
    ...    ${SDCIO_CONFIGSET_INTENTS}
    ...    ${intent}
    IF    ${is_configset}
        kubectl patch    configset    ${intent}-sros    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    ELSE
        kubectl patch    config    ${intent}-sros    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END

Create Deviations For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Log    Creating deviations on ${node} for intent ${intent}
        Set Config on node via file
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=${intents.${intent}}]/"
        ...    ${CURDIR}/input/sros/deviations-${intent}.json
    END

Reject Deviations For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{targetnodes}
        ${deviation_name} =    Get Deviation Name    ${intent}    ${node}
        Delete Deviation    ${deviation_name}
    END

Verify Deviation Count For Intent
    [Arguments]    ${intent}    ${expected_count}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
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
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Get Config from node and Verify Intent
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
        ...    ${expectedoutput}
        ...    ${filter}
    END

Partial Revert Deviations For Intent by Admin State
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    ${targetnode} =    Get From List    ${targetnodes}    0
    ${deviation_name} =    Get Deviation Name    ${intent}    ${targetnode}
    ${filter_path} =    Set Variable    /configure/service/vprn[service-name=${intents.${intent}}]/admin-state
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc deviation --deviation ${deviation_name} --filter-path ${filter_path} --revert
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Verify Deviation on k8s
    ...    ${deviation_name}
    ...    2

Get Deviation Name
    [Arguments]    ${intent}    ${node}
    ${is_configset} =    Run Keyword And Return Status
    ...    List Should Contain Value
    ...    ${SDCIO_CONFIGSET_INTENTS}
    ...    ${intent}
    IF    ${is_configset}
        RETURN    ${intent}-sros-${node}
    END
    RETURN    ${intent}-sros
