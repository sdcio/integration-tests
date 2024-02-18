*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON


*** Keywords ***
Targets Check Ready
    [Documentation]    Make sure the discovered Targets are ready
    [Arguments]    ${namespace}    ${node}

    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.inv.sdcio.dev -o=jsonpath='{.status}' ${node}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.conditions[*].status
    Should be equal as strings    ${status}    ['True', 'True', 'True', 'True']
