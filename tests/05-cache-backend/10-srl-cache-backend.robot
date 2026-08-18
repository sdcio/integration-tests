*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Library             RPA.JSON
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/config-server.robot
Resource            ../Keywords/gnmic.robot

Suite Setup         Setup
Suite Teardown      Cleanup

*** Variables ***
${INTENT_NAME}          intent-cache-backend-srl
${TARGET}                srl1
${IFACE}                ethernet-1/10
${DESCRIPTION}          cache-backend-e2e
${options}              --skip-verify -e PROTO
${eventual_timeout}     2min
${retry}                2s

*** Test Cases ***
TC1: CRUD Round Trip Reads Flow Through ConfigReadService
    [Documentation]    The intent applied in Suite Setup is Ready and reflected on the device;
    ...    GetIntent (via `kubectl sdc runningconfig`) and BlameConfig (via `kubectl sdc blame`)
    ...    both read back the expected description — proving these reads flow through
    ...    ConfigReadService rather than any local, in-process cache state.
    [Tags]    happy-path    crud
    Verify Interface Description On Device    ${TARGET}    ${IFACE}    ${DESCRIPTION}
    Verify Running Config Contains Description    ${TARGET}    ${DESCRIPTION}
    Verify Blame Contains Description    ${TARGET}    ${DESCRIPTION}

TC2: Restart Recovery Via TargetSnapshot After data-server-controller Restart
    [Documentation]    Restart the data-server-controller StatefulSet and confirm the
    ...    previously-applied intent is still readable afterward — via the device, GetIntent,
    ...    and BlameConfig — proving correctness depends on TargetSnapshot via ConfigReadService,
    ...    not an in-process cache that would be lost on restart. Polls for StatefulSet/Config
    ...    readiness rather than asserting immediately, per this repo's reconciler-timing
    ...    conventions (PROJECT_CONTEXT.md).
    [Tags]    recovery
    ${desc_before} =    Get Interface Description On Device    ${TARGET}    ${IFACE}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl rollout restart statefulset/${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Wait Until Keyword Succeeds    5min    5s
    ...    Config-Server until data-server-controller StatefulSet ready
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT_NAME}
    ${desc_after} =    Get Interface Description On Device    ${TARGET}    ${IFACE}
    Should Be Equal    ${desc_before}    ${desc_after}
    Verify Running Config Contains Description    ${TARGET}    ${DESCRIPTION}
    Verify Blame Contains Description    ${TARGET}    ${DESCRIPTION}

*** Keywords ***
Setup
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${TARGET}
    kubectl apply    ${CURDIR}/input/intent-cache-backend-srl.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT_NAME}

Cleanup
    Run Keyword And Ignore Error
    ...    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT_NAME}
    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Run Keyword And Expect Error    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${INTENT_NAME}
    Run Keyword And Ignore Error
    ...    Run Keyword If Any Tests Failed    Delete Config from node
    ...    ${TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${IFACE}]"

Get Interface Description On Device
    [Documentation]    Retrieve the description leaf value of an interface from the device via gnmic.
    [Arguments]    ${target}    ${iface}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${target}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path "/interface[name=${iface}]/description" | jq -r '.[0].updates[0].values["interface/description"]'
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${output}

Verify Interface Description On Device
    [Documentation]    Assert that the interface description on the device matches the expected value.
    [Arguments]    ${target}    ${iface}    ${expected_value}
    ${output} =    Get Interface Description On Device    ${target}    ${iface}
    Should Be Equal    ${output}    ${expected_value}

Verify Running Config Contains Description
    [Documentation]    GetIntent seam: `kubectl sdc runningconfig` calls data-server's GetIntent RPC
    ...    (config-server's Target.GetRunningConfig, with Intent=running) through the aggregated
    ...    API server. Under Cache.Type: config-server this read is served by ConfigReadService,
    ...    not any local, in-process cache — so this assertion is the CRUD-round-trip/recovery
    ...    proof point for GetIntent.
    [Arguments]    ${target}    ${expected_description}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc runningconfig --target ${target} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${expected_description}

Verify Blame Contains Description
    [Documentation]    BlameConfig seam: `kubectl sdc blame` calls data-server's BlameConfig RPC
    ...    through the aggregated API server. Under Cache.Type: config-server this read is served
    ...    by ConfigReadService, not any local, in-process cache — so this assertion is the
    ...    CRUD-round-trip/recovery proof point for BlameConfig.
    [Arguments]    ${target}    ${expected_description}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc blame --target ${target} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${expected_description}
