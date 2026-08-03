*** Settings ***
Resource    k8s/kubectl.robot
Resource    ../variables.robot
Library     RPA.JSON


*** Keywords ***
Targets Check Ready
    [Documentation]    Make sure the discovered Targets are ready
    [Arguments]    ${namespace}    ${node}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=json ${node}
    Log     ${output}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=jsonpath='{.status}' ${node}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.conditions[*].status
    Should be equal as strings    ${status}    ['True', 'True', 'True', 'True', 'True']

Wait Until Target Ready
    [Documentation]    Waits for a Target to report all conditions ready. On timeout, dumps
    ...    discovery diagnostics (Target list, DiscoveryRule status, api-server logs) before
    ...    failing with a clear message — instead of the opaque "1 != 0" a raw
    ...    "Wait Until Keyword Succeeds" + "Should Be Equal As Strings" failure produces.
    ...    Common root cause covered by this: the Target CR is never created at all
    ...    (discovery never finds the device) rather than being created-but-not-ready;
    ...    the diagnostics below distinguish the two.
    [Arguments]    ${namespace}    ${node}    ${timeout}=15min    ${retry}=10s
    ${ready} =    Run Keyword And Return Status
    ...    Wait Until Keyword Succeeds    ${timeout}    ${retry}    Targets Check Ready    ${namespace}    ${node}
    IF    not ${ready}
        Log Target discovery diagnostics    ${namespace}    ${node}
        Fail    Target '${node}' not ready within ${timeout} - see discovery diagnostics above (logged at WARN)
    END

Log Target discovery diagnostics
    [Documentation]    Best-effort snapshot of discovery/target state when a Target fails to
    ...    become ready in time. Logged at WARN so it is visible without verbose mode.
    [Arguments]    ${namespace}    ${node}
    Log    === Target/Discovery diagnostics for '${node}' ===    WARN
    Kubectl log diagnostic    get targets.config.sdcio.dev -n ${namespace} -o wide
    Kubectl log diagnostic    get targets.config.sdcio.dev ${node} -n ${namespace} -o yaml
    Kubectl log diagnostic    get discoveryrules.inv.sdcio.dev -n ${namespace} -o yaml
    Kubectl log diagnostic    get pods -n ${SDCIO_SYSTEM_NAMESPACE} -o wide
    Kubectl log diagnostic    logs deployment/api-server -n ${SDCIO_SYSTEM_NAMESPACE} -c api-server --tail=500

Target Check Ready With Profiles
    [Documentation]    Make sure the discovered Target is ready and uses the expected connection and sync profiles
    [Arguments]    ${namespace}    ${node}    ${connection_profile}    ${sync_profile}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=json ${node}
    Log     ${output}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[*].status
    Should be equal as strings    ${status}    ['True', 'True', 'True', 'True', 'True']
    ${target_connection_profile} =    Get values from JSON    ${json}    $.spec.connectionProfile
    Should be equal as strings    ${target_connection_profile}    ['${connection_profile}']
    ${target_sync_profile} =    Get values from JSON    ${json}    $.spec.syncProfile
    Should be equal as strings    ${target_sync_profile}    ['${sync_profile}']
