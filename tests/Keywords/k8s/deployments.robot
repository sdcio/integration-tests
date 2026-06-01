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