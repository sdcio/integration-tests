*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/config-server.robot
Resource            ../Keywords/data-server.robot
Resource            ../Keywords/gnmic.robot

Suite Setup         Setup
Suite Teardown      Cleanup

*** Variables ***
${INTENT_NAME}          intent-cache-backend-srl
${TARGET}                srl1
${IFACE}                ethernet-1/10
${DESCRIPTION}          cache-backend-e2e
${DRIFT_DESCRIPTION}    drift-before-revert
${options}              --skip-verify -e PROTO
${eventual_timeout}     2min
${retry}                2s
${sync_revert_timeout}  2min

*** Test Cases ***
TC1: CRUD Round Trip Reads Flow Through ConfigReadService
    [Documentation]    The intent applied in Suite Setup is Ready and reflected on the device;
    ...    named-intent GetIntent (gRPC), BlameConfig (`kubectl sdc blame`), and running
    ...    export (`kubectl sdc runningconfig`) all read back the expected description.
    ...    Named-intent GetIntent and BlameConfig both load intents via ConfigReadService;
    ...    runningconfig reads the in-memory sync tree only.
    [Tags]    happy-path    crud
    Verify Interface Description On Device    ${TARGET}    ${IFACE}    ${DESCRIPTION}
    Verify Intent Get Contains Description    ${TARGET}    ${INTENT_NAME}    ${DESCRIPTION}
    Verify Blame Contains Description    ${TARGET}    ${DESCRIPTION}
    Verify Running Config Contains Description    ${TARGET}    ${DESCRIPTION}

TC2: Restart Recovery Via TargetSnapshot After data-server-controller Restart
    [Documentation]    Restart the data-server-controller StatefulSet and confirm the
    ...    previously-applied intent is still readable afterward — via the device,
    ...    named-intent GetIntent, BlameConfig, and running export — proving correctness
    ...    depends on TargetSnapshot via ConfigReadService, not an in-process cache that
    ...    would be lost on restart. Polls for StatefulSet/Config readiness rather than
    ...    asserting immediately, per this repo's reconciler-timing conventions.
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
    Verify Intent Get Contains Description    ${TARGET}    ${INTENT_NAME}    ${DESCRIPTION}
    Verify Blame Contains Description    ${TARGET}    ${DESCRIPTION}
    Verify Running Config Contains Description    ${TARGET}    ${DESCRIPTION}

TC3: Sync Revert Reloads Intents After Device Drift
    [Documentation]    Introduce device drift and wait for periodic sync to revert it.
    ...    This exercises performRevert's LoadAllButRunningIntents path, which must
    ...    assemble root-path Config blobs from ConfigReadService on every sync cycle.
    [Tags]    sync    revert
    Set Interface Description On Device    ${TARGET}    ${IFACE}    ${DRIFT_DESCRIPTION}
    Wait Until Keyword Succeeds    ${sync_revert_timeout}    5s
    ...    Verify Interface Description On Device    ${TARGET}    ${IFACE}    ${DESCRIPTION}
    Verify Intent Get Contains Description    ${TARGET}    ${INTENT_NAME}    ${DESCRIPTION}
    Verify Blame Contains Description    ${TARGET}    ${DESCRIPTION}

*** Keywords ***
Setup
    Assert Deployed Cache Type Is Config Server
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${TARGET}
    kubectl apply    ${CURDIR}/input/intent-cache-backend-srl.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT_NAME}

Cleanup
    Run Keyword And Ignore Error    Stop Data Server gRPC Port Forward
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

Set Interface Description On Device
    [Documentation]    Set the description leaf on a target interface via gnmic, creating drift.
    [Arguments]    ${target}    ${iface}    ${value}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${target}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} set --update-path "/interface[name=${iface}]/description" --update-value "${value}"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify Interface Description On Device
    [Documentation]    Assert that the interface description on the device matches the expected value.
    [Arguments]    ${target}    ${iface}    ${expected_value}
    ${output} =    Get Interface Description On Device    ${target}    ${iface}
    Should Be Equal    ${output}    ${expected_value}

Verify Running Config Contains Description
    [Documentation]    Running export seam: `kubectl sdc runningconfig` calls GetIntent(running)
    ...    and reads the in-memory sync tree. It does not load named intents from
    ...    ConfigReadService, so it is not sufficient alone to prove cache-backend import.
    [Arguments]    ${target}    ${expected_description}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc runningconfig --target ${target} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${expected_description}

Verify Blame Contains Description
    [Documentation]    BlameConfig seam: `kubectl sdc blame` calls LoadAllButRunningIntents,
    ...    which under Cache.Type: config-server assembles intent blobs from
    ...    ConfigReadService via mergeConfigBlobs.
    [Arguments]    ${target}    ${expected_description}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc blame --target ${target} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${expected_description}

Assert Deployed Cache Type Is Config Server
    [Documentation]    Fail fast when this suite runs against a cluster not deployed with
    ...    Cache.Type: config-server — prevents a false pass on the local-backed backend.
    ${rc}    ${cache_type}=    Run And Return Rc And Output
    ...    kubectl get configmap data-server -n ${SDCIO_SYSTEM_NAMESPACE} -o jsonpath={.data.data-server\\.yaml} | yq -r .cache.type
    Log    ${cache_type}
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal    ${cache_type}    config-server
