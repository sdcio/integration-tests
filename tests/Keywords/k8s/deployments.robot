*** Settings ***
Resource            kubectl.robot



*** Keywords ***
Integer From Replica Status
    [Documentation]    Kubernetes omits replica status fields when they are 0, so jsonpath returns ''. Treat that as 0.
    [Arguments]    ${output}
    ${result}=    Evaluate    int((str($output) if $output is not None else '').strip() or '0')
    RETURN    ${result}

Deployment AvailableReplicas
    [Documentation]     Runs kubectl get for the deployment as YAML (logged), then kubectl get with jsonpath for availableReplicas to assert against ${min-count-available}.
    [Arguments]    ${namespace}    ${deployment}    ${min-count-available}=1
    kubectl get    -n ${namespace} deployments.apps ${deployment} -o yaml
    ${rc}    ${output} =     kubectl get    -n ${namespace} deployments.apps -o=jsonpath='{.status.availableReplicas}' ${deployment}
    ${result} =    Integer From Replica Status    ${output}
    Should Be True    ${result} >= ${min-count-available}

Wait Until Deployment AvailableReplicas
    [Documentation]    Poll until the Deployment has enough availableReplicas. On timeout, dump pod/deploy/events diagnostics (WARN) so CI shows ImagePullBackOff, PVC bind, crash loops, etc.
    [Arguments]    ${namespace}    ${deployment}    ${timeout}=3 min    ${retry_interval}=2 sec    ${min-count-available}=1
    ${ready}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    ${timeout}    ${retry_interval}    Deployment AvailableReplicas    ${namespace}    ${deployment}    ${min-count-available}
    IF    not ${ready}
        Log Deployment diagnostics    ${namespace}    ${deployment}
        Fail    Deployment ${namespace}/${deployment} did not reach ${min-count-available} available replica(s) within ${timeout}
    END

Log Deployment diagnostics
    [Documentation]    Best-effort kubectl snapshot when a Deployment fails readiness (logs at WARN). Does not fail the caller.
    [Arguments]    ${namespace}    ${deployment}
    Log    === deployment ${namespace}/${deployment} diagnostics ===    WARN
    Kubectl log diagnostic    get deploy ${deployment} -n ${namespace} -o wide
    Kubectl log diagnostic    describe deploy ${deployment} -n ${namespace}
    Kubectl log diagnostic    get pods -n ${namespace} -o wide
    Kubectl log diagnostic    describe pods -n ${namespace}
    Kubectl log diagnostic    get events -n ${namespace} --sort-by=.lastTimestamp

StatefulSet Ready Replicas
    [Documentation]     Waits until a StatefulSet reports at least ${min-count-available} ready replicas (default 1).
    [Arguments]    ${namespace}    ${statefulset}    ${min-count-available}=1
    kubectl get    -n ${namespace} statefulsets.apps ${statefulset} -o yaml
    ${rc}    ${output} =     kubectl get    -n ${namespace} statefulsets.apps -o=jsonpath='{.status.readyReplicas}' ${statefulset}
    ${result} =    Integer From Replica Status    ${output}
    Should Be True    ${result} >= ${min-count-available}
