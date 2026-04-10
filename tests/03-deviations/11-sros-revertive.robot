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

@{SDCIO_SROS_NODES}     sr1    sr2
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4
&{intents}        intent1=vprn123    intent2=vprn234    intent3=vprn789    intent4=vprn987
${retry}    2s
${eventual_timeout}    2min
${options}    --insecure -e JSON
${filter}    "configure/service/vprn"
${VERIFY_IMMEDIATE_DEVICE_DELETE}    ${FALSE}
${INTENT_TARGET_CACHE}    ${None}

*** Test Cases ***
Delete SROS device config and Verify Revertive Deviations - intent1
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent1
    Run Delete And Verify Revertive For Intent    intent1

Delete SROS device config and Verify Revertive Deviations - intent2
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent2
    Run Delete And Verify Revertive For Intent    intent2

Delete SROS device config and Verify Revertive Deviations - intent3
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent3
    Run Delete And Verify Revertive For Intent    intent3

Delete SROS device config and Verify Revertive Deviations - intent4
    [Documentation]    Delete device config and verify revertive behavior for one intent.
    [Tags]    revertive    delete-config    verify    intent4
    Run Delete And Verify Revertive For Intent    intent4

Delete ALL SROS device config and Verify Revertive Deviations
    [Documentation]    Delete device config and Verify Revertive Deviations on Config(Set) -- multiple intents at once
    Delete All Device Config
    Verify All Intents Are Reverted

Adjust SROS device config and Verify Revertive Deviations - intent1
    [Documentation]    Adjust SROS config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent1
    Run Adjust And Verify Revertive For Intent    intent1

Adjust SROS device config and Verify Revertive Deviations - intent2
    [Documentation]    Adjust SROS config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent2
    Run Adjust And Verify Revertive For Intent    intent2

Adjust SROS device config and Verify Revertive Deviations - intent3
    [Documentation]    Adjust SROS config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent3
    Run Adjust And Verify Revertive For Intent    intent3

Adjust SROS device config and Verify Revertive Deviations - intent4
    [Documentation]    Adjust SROS config and verify revertive behavior for one intent.
    [Tags]    revertive    adjust-config    verify    intent4
    Run Adjust And Verify Revertive For Intent    intent4

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Wait Until Keyword Succeeds    5min    ${retry}    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    Initialize Intent Target Cache    ${CURDIR}/input/sros    -sros

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
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Log    Deleting config for intent ${intent} on ${node}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
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
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
    ...    ${filter}
    ${output} =    Evaluate    [i for i in ${output} if i]
    Should Be Empty    ${output}

Adjust Device Config For Intent
    [Arguments]    ${intent}
    @{targetnodes} =    Get Target Nodes For Intent    ${intent}    ${SDCIO_SROS_NODES}
    FOR    ${node}    IN    @{targetnodes}
        Log    Adjusting config for intent ${intent} on ${node}
        Set Config on node via file
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=${intents.${intent}}]/"
        ...    ${CURDIR}/input/sros/deviations-${intent}.json
    END

Verify Intent Is Reverted
    [Arguments]    ${intent}
    @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
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

Delete All Device Config
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Log    Deleting all vprn config on ${node}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=*]"
        Run Keyword If    ${VERIFY_IMMEDIATE_DEVICE_DELETE}
        ...    Verify All Intent Config Is Deleted On Node
        ...    ${node}
    END

Verify All Intent Config Is Deleted On Node
    [Arguments]    ${node}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=*]"
    ...    ${filter}
    ${output} =    Evaluate    [i for i in ${output} if i]
    Should Be Empty    ${output}

Verify All Intents Are Reverted
    @{all_intents} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}
    FOR    ${intent}    IN    @{all_intents}
        Verify Intent Is Reverted    ${intent}
    END

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
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "customer"

DeleteAll
    Log    Deleting all SROS Config
    FOR  ${node}    IN    @{SDCIO_SROS_NODES}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=*]"
    END
