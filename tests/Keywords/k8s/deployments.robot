*** Settings ***
Resource            kubectl.robot



*** Keywords ***
Deployment AvailableReplicas
    [Documentation]     Runs kubectl get for the deployment as YAML (logged), then kubectl get with jsonpath for availableReplicas to assert against ${min-count-available}.
    [Arguments]    ${namespace}    ${deployment}    ${min-count-available}=1
    kubectl get    -n ${namespace} deployments.apps ${deployment} -o yaml
    ${rc}    ${output} =     kubectl get    -n ${namespace} deployments.apps -o=jsonpath='{.status.availableReplicas}' ${deployment}
    ${result} =	    Convert To Integer    ${output}
    Should Be True    ${result} >= ${min-count-available}

StatefulSet Ready Replicas
    [Documentation]     Waits until a StatefulSet reports at least ${min-count-available} ready replicas (default 1).
    [Arguments]    ${namespace}    ${statefulset}    ${min-count-available}=1
    kubectl get    -n ${namespace} statefulsets.apps ${statefulset} -o yaml
    ${rc}    ${output} =     kubectl get    -n ${namespace} statefulsets.apps -o=jsonpath='{.status.readyReplicas}' ${statefulset}
    ${result} =    Convert To Integer    ${output}
    Should Be True    ${result} >= ${min-count-available}