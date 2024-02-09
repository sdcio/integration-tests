*** Settings ***
Resource    k8s/kubectl.robot


*** Keywords ***
Schemas Check Loaded
    [Documentation]    Make sure the referenced schemas is being loaded properly
    [Arguments]    ${namespace}    ${schema}
    
    ${rc}    ${output} =    kubectl get     -n ${namespace} schemas.inv.sdcio.dev -o=jsonpath='{.status.conditions[0]}' ${schema}

    Should Contain    ${output}    "status":"True"
    Should Contain    ${output}    "type":"Ready"