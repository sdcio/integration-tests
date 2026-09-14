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
Resource            ../Keywords/deviation.robot

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

# TC4 — ghost + unrelated delete (SROS: mirrors the CI regression this spec closes,
# a vprn leafref-referencing a customer object — see the spec's "Further Notes" /
# ticket 06 for the originating CI run reference).
${SROS_TARGET}                  sr1
${SROS_options}                 --insecure -e JSON
${CB_CUSTOMER_NAME}             cache-backend-customer
${CB_CUSTOMER_ID}               9
${CB_INTENT1_SROS_NAME}         cache-backend-intent1-sros
${CB_VPRN_SERVICE_NAME}         vprn900
${CB_VPRN_FILTER}               "configure/service/vprn"
${CB_CUSTOMER_FILTER}           "configure/service/customer"

# TC5 — apply→Confirm window (SRL, dedicated intent).
${CB_APPLY_CONFIRM_NAME}        cache-backend-apply-confirm-srl
${CB_APPLY_CONFIRM_IFACE}       ethernet-1/11
${CB_APPLY_CONFIRM_DESCRIPTION}    cache-backend-apply-confirm

# TC6 — rollback (SRL, dedicated intent).
${CB_ROLLBACK_NAME}             cache-backend-rollback-srl
${CB_ROLLBACK_IFACE}            ethernet-1/12
${CB_ROLLBACK_GOOD_DESCRIPTION}    cache-backend-rollback-good
# Assumed absent from the containerlab SRL image's provisioned port range, so the
# device rejects this push after config-server's generic schema validation has
# already accepted it — the device-side failure this scenario needs. Adjust if the
# CI topology ever provisions this port.
${CB_ROLLBACK_BAD_IFACE}        ethernet-1/999

# TC7 — recovery (SRL, dedicated intent).
${CB_RECOVERY_NAME}             cache-backend-recovery-srl
${CB_RECOVERY_IFACE}            ethernet-1/13
${CB_RECOVERY_DESCRIPTION}      cache-backend-recovery

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

TC4: Ghost + Unrelated Delete Does Not Block ConfigSet-style Teardown
    [Documentation]    Reproduces the CI regression this spec closes: a vprn Config
    ...    (${CB_INTENT1_SROS_NAME}) leafref-references a customer Config
    ...    (${CB_CUSTOMER_NAME}) on the same SROS target. Deleting the vprn intent
    ...    must remove it from the device AND from TargetSnapshot immediately
    ...    (apply-time IntentDelete, not gated on post-Confirm saveSnapshot) so that
    ...    the unrelated customer delete right after it does not see a ghost vprn
    ...    still leafref-referencing the customer being torn down.
    [Tags]    regression    ghost    delete
    kubectl apply    ${CURDIR}/input/sros/cache-backend-customer.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_CUSTOMER_NAME}
    kubectl apply    ${CURDIR}/input/sros/cache-backend-intent1-sros.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_INTENT1_SROS_NAME}
    Verify SROS Service Present    ${SROS_TARGET}    ${CB_VPRN_FILTER}
    ...    "/configure/service/vprn[service-name=${CB_VPRN_SERVICE_NAME}]"
    TargetSnapshot Should Contain Key    ${SROS_TARGET}    ${CB_INTENT1_SROS_NAME}

    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_INTENT1_SROS_NAME}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Verify SROS Service Absent    ${SROS_TARGET}    ${CB_VPRN_FILTER}
    ...    "/configure/service/vprn[service-name=${CB_VPRN_SERVICE_NAME}]"
    TargetSnapshot Should Not Contain Key    ${SROS_TARGET}    ${CB_INTENT1_SROS_NAME}

    # The actual regression: this delete must succeed on its own merits — no leafref
    # failure from a ghosted vprn, no "unknown intent" abort.
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_CUSTOMER_NAME}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Verify SROS Service Absent    ${SROS_TARGET}    ${CB_CUSTOMER_FILTER}
    ...    "/configure/service/customer[customer-name=${CB_CUSTOMER_ID}]"
    TargetSnapshot Should Not Contain Key    ${SROS_TARGET}    ${CB_CUSTOMER_NAME}

TC5: Delete Is Visible Immediately, Not Gated On Post-Confirm saveSnapshot
    [Documentation]    Last-applied must update inside TransactionSet at apply time,
    ...    not lag until saveSnapshot runs after TransactionConfirm. Deletes a
    ...    dedicated intent and checks — in a single shot, no eventual-consistency
    ...    retry loop — that the device, GetIntent, and blame are all already
    ...    consistent with the delete the moment the device confirms it, closing the
    ...    apply→Confirm window the ghost-intent bug lived in.
    [Tags]    regression    apply-confirm-window
    kubectl apply    ${CURDIR}/input/srl/cache-backend-apply-confirm-srl.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_APPLY_CONFIRM_NAME}
    Verify Interface Description On Device    ${TARGET}    ${CB_APPLY_CONFIRM_IFACE}    ${CB_APPLY_CONFIRM_DESCRIPTION}

    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_APPLY_CONFIRM_NAME}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Verify Interface Absent On Device    ${TARGET}    ${CB_APPLY_CONFIRM_IFACE}

    # No Wait Until Keyword Succeeds below — the device already confirmed the delete
    # above, so last-applied must already be consistent, not merely eventually so.
    TargetSnapshot Should Not Contain Key    ${TARGET}    ${CB_APPLY_CONFIRM_NAME}
    Verify Intent Get Does Not Exist    ${TARGET}    ${CB_APPLY_CONFIRM_NAME}
    Verify Blame Does Not Contain Description    ${TARGET}    ${CB_APPLY_CONFIRM_DESCRIPTION}
    Verify No Deviation For Deleted Intent    ${CB_APPLY_CONFIRM_NAME}

TC6: Failed Apply Does Not Corrupt Last-Applied
    [Documentation]    A push that config-server's generic schema validation accepts
    ...    but the device rejects at commit must not leave last-applied pointing at
    ...    the bad, never-applied value — it must still reflect the last value that
    ...    actually reached the device, on the device itself and via GetIntent/blame.
    ...    NOTE: this is a related-but-distinct bug class from the spec's literal
    ...    "cancel/timeout rollback restores TargetSnapshot" scenario (Testing
    ...    Decisions — Level 2, item 3), which needs a compensating-write rollback
    ...    triggered by an RPC timeout/cancellation — not reproducible black-box in
    ...    this suite without a fault-injection seam this repo doesn't have yet. See
    ...    ticket 06's Comments for detail.
    [Tags]    regression    apply-failure
    kubectl apply    ${CURDIR}/input/srl/cache-backend-rollback-srl.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_ROLLBACK_NAME}
    Verify Interface Description On Device    ${TARGET}    ${CB_ROLLBACK_IFACE}    ${CB_ROLLBACK_GOOD_DESCRIPTION}
    Verify Intent Get Contains Description    ${TARGET}    ${CB_ROLLBACK_NAME}    ${CB_ROLLBACK_GOOD_DESCRIPTION}

    kubectl patch    config    ${CB_ROLLBACK_NAME}
    ...    '{"spec": {"config": [{"path": "/", "value": {"interface": [{"name": "${CB_ROLLBACK_BAD_IFACE}", "admin-state": "enable", "description": "cache-backend-rollback-bad"}]}}]}}'
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Not Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_ROLLBACK_NAME}

    # The old-good interface/description must still be present — the bad value was
    # never applied, and last-applied was not advanced or blanked out by the failure.
    Verify Interface Description On Device    ${TARGET}    ${CB_ROLLBACK_IFACE}    ${CB_ROLLBACK_GOOD_DESCRIPTION}
    Verify Intent Get Contains Description    ${TARGET}    ${CB_ROLLBACK_NAME}    ${CB_ROLLBACK_GOOD_DESCRIPTION}
    Verify Blame Contains Description    ${TARGET}    ${CB_ROLLBACK_GOOD_DESCRIPTION}

TC7: Recovery Does Not Replay A Delete Applied Before Restart
    [Documentation]    Delete an intent, then restart data-server-controller before
    ...    the next sync/reconcile cycle would otherwise have re-confirmed the
    ...    delete. The deleted intent must not be replayed onto the device on
    ...    recovery — proving recovery replays only what is still last-applied, not
    ...    a stale in-memory view that predates the delete.
    [Tags]    regression    recovery
    kubectl apply    ${CURDIR}/input/srl/cache-backend-recovery-srl.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_RECOVERY_NAME}
    Verify Interface Description On Device    ${TARGET}    ${CB_RECOVERY_IFACE}    ${CB_RECOVERY_DESCRIPTION}

    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_RECOVERY_NAME}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Verify Interface Absent On Device    ${TARGET}    ${CB_RECOVERY_IFACE}
    TargetSnapshot Should Not Contain Key    ${TARGET}    ${CB_RECOVERY_NAME}

    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl rollout restart statefulset/${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Wait Until Keyword Succeeds    5min    5s
    ...    Config-Server until data-server-controller StatefulSet ready

    Verify Interface Absent On Device    ${TARGET}    ${CB_RECOVERY_IFACE}
    TargetSnapshot Should Not Contain Key    ${TARGET}    ${CB_RECOVERY_NAME}
    Verify Intent Get Does Not Exist    ${TARGET}    ${CB_RECOVERY_NAME}

*** Keywords ***
Setup
    Assert Deployed Cache Type Is Config Server
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${TARGET}
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${SROS_TARGET}
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
    # Best-effort cleanup for TC4-TC7 fixtures — idempotent no-ops if a test already
    # deleted its own Config, only matters when a test failed mid-scenario.
    Run Keyword And Ignore Error    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_INTENT1_SROS_NAME}
    Run Keyword And Ignore Error    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_CUSTOMER_NAME}
    Run Keyword And Ignore Error    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_APPLY_CONFIRM_NAME}
    Run Keyword And Ignore Error    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_ROLLBACK_NAME}
    Run Keyword And Ignore Error    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${CB_RECOVERY_NAME}
    Run Keyword And Ignore Error
    ...    Delete Config from node    ${SROS_TARGET}    ${SROS_options}    ${SROS_USERNAME}    ${SROS_PASSWORD}
    ...    "/configure/service/vprn[service-name=${CB_VPRN_SERVICE_NAME}]"
    Run Keyword And Ignore Error
    ...    Delete Config from node    ${SROS_TARGET}    ${SROS_options}    ${SROS_USERNAME}    ${SROS_PASSWORD}
    ...    "/configure/service/customer[customer-name=${CB_CUSTOMER_ID}]"
    Run Keyword And Ignore Error
    ...    Delete Config from node    ${TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${CB_APPLY_CONFIRM_IFACE}]"
    Run Keyword And Ignore Error
    ...    Delete Config from node    ${TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${CB_ROLLBACK_IFACE}]"
    Run Keyword And Ignore Error
    ...    Delete Config from node    ${TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${CB_RECOVERY_IFACE}]"

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
    ...    kubectl get configmap data-server -n ${SDCIO_SYSTEM_NAMESPACE} -o jsonpath='{.data.data-server\\.yaml}' | yq -r .cache.type
    Log    ${cache_type}
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal    ${cache_type}    config-server

TargetSnapshot Should Contain Key
    [Documentation]    Assert that ${key} is present in TargetSnapshot.Spec.Configs for
    ...    ${target} — the write-path membership rule this spec's Modify/Delete RPCs
    ...    implement directly against config-server's colocated aggregated API.
    [Arguments]    ${target}    ${key}
    ${output} =    kubectl get jsonpath
    ...    targetsnapshots.config.sdcio.dev    ${target}    ${SDCIO_RESOURCE_NAMESPACE}
    ...    {.spec.configs.${key}}
    Should Not Be Empty    ${output}

TargetSnapshot Should Not Contain Key
    [Documentation]    Assert that ${key} is absent from TargetSnapshot.Spec.Configs for
    ...    ${target} — on delete, IntentDelete removes the map key outright (no tombstone).
    [Arguments]    ${target}    ${key}
    ${output} =    kubectl get jsonpath
    ...    targetsnapshots.config.sdcio.dev    ${target}    ${SDCIO_RESOURCE_NAMESPACE}
    ...    {.spec.configs.${key}}
    Should Be Empty    ${output}

Verify Interface Absent On Device
    [Documentation]    Assert that an SRL interface no longer carries the description leaf
    ...    (interface config was removed, not merely admin-disabled).
    [Arguments]    ${target}    ${iface}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${target}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path "/interface[name=${iface}]/description"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${json} =    Convert string to JSON    ${output}
    ${values} =    Get values from JSON    ${json}    $.[*].updates.[*]
    ${values} =    Evaluate    [v for v in ${values} if v]
    Should Be Empty    ${values}

Verify SROS Service Present
    [Documentation]    Assert a service subtree is configured on the SROS device.
    [Arguments]    ${target}    ${filter}    ${path}
    ${output} =    Get Config from node
    ...    ${target}    ${SROS_options}    ${SROS_USERNAME}    ${SROS_PASSWORD}
    ...    ${path}    ${filter}
    ${output} =    Evaluate    [i for i in ${output} if i]
    Should Not Be Empty    ${output}

Verify SROS Service Absent
    [Documentation]    Assert a service subtree is gone from the SROS device — used both
    ...    for the deleted vprn (ghost check) and the deleted customer (the actual
    ...    regression: this delete must succeed on its own, with no leafref ghost from
    ...    an already-deleted vprn intent blocking it).
    [Arguments]    ${target}    ${filter}    ${path}
    ${output} =    Get Config from node
    ...    ${target}    ${SROS_options}    ${SROS_USERNAME}    ${SROS_PASSWORD}
    ...    ${path}    ${filter}
    ${output} =    Evaluate    [i for i in ${output} if i]
    Should Be Empty    ${output}

Verify No Deviation For Deleted Intent
    [Documentation]    Assert a deleted intent shows no ghost deviation during the
    ...    apply→Confirm window. If config-server garbage-collects the Deviation CR
    ...    along with its owning Config, absence is itself proof of no ghost deviation;
    ...    if it still exists, its deviations list must be empty.
    [Arguments]    ${name}
    ${deviation_name} =    Get Config Deviation Resource Name    ${name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${deviation_name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    IF    ${rc} != 0
        RETURN
    END
    ${json} =    Convert string to JSON    ${output}
    ${deviations} =    Get values from JSON    ${json}    $.spec.deviations[*]
    Should Be Empty    ${deviations}

Verify Intent Get Does Not Exist
    [Documentation]    Named-intent GetIntent must not resolve a deleted intent — asserts
    ...    a non-zero/error response rather than a stale hit, the ghost-intent signature.
    [Arguments]    ${target}    ${intent_name}
    Ensure Data Server gRPC Port Forward
    ${datastore}=    Catenate    SEPARATOR=.    ${SDCIO_RESOURCE_NAMESPACE}    ${target}
    ${request}=    Set Variable    {"datastoreName":"${datastore}","intent":"${intent_name}","format":1}
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    grpcurl -plaintext -d '${request}' localhost:${DATA_SERVER_GRPC_LOCAL_PORT} data.DataServer/GetIntent
    Log    ${output}
    Should Not Be Equal As Integers    ${rc}    0

Verify Blame Does Not Contain Description
    [Documentation]    BlameConfig must not surface a description that belonged to an
    ...    already-deleted intent (the ghost-intent-in-LoadAll signature).
    [Arguments]    ${target}    ${unexpected_description}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc blame --target ${target} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Not Contain    ${output}    ${unexpected_description}
