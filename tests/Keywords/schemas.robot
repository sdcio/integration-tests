*** Settings ***
Library             OperatingSystem


*** Keywords ***
Schemas Check Loaded
    [Documentation]    Make sure the referenced schemas is being loaded properly
    [Arguments]    ${namespace}    ${schema}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get -n ${namespace} schemas.inv.sdcio.dev -o=jsonpath='{.status.conditions[0]}' ${schema}
    Log    ${output}
    Should Contain    ${output}    "status":"True"
    Should Contain    ${output}    "type":"Ready"
    Should Be Equal As Integers    ${rc}    0
    
