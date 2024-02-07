*** Settings ***
Resource            kubectl.robot



*** Keywords ***
Deployment AvailableReplicas
    [Documentation]     Issues a kubectl get, extracting the availableReplicas from the status.
    [Arguments]    ${namespace}    ${deployment}    ${min-count-available}=1
    ${rc}    ${output} =     kubectl get    -n ${namespace} deployments.apps -o=jsonpath='{.status.availableReplicas}' ${deployment}
    ${result} =	    Convert To Integer    ${output}
    Should Be True    ${result} >= ${min-count-available}