*** Settings ***
Library             OperatingSystem


*** Keywords ***
Deployment AvailableReplicas
    [Arguments]    ${namespace}    ${deployment}    ${min-count-available}=1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get -n ${namespace} deployments.apps -o=jsonpath='{.status.availableReplicas}' ${deployment}
    Log    ${output}
    ${result} =	    Convert To Integer    ${output}
    Should Be True    ${result} >= ${min-count-available}
    Should Be Equal As Integers    ${rc}    0