*** Settings ***
Library             OperatingSystem

*** Keywords ***
kubectl apply
    [Documentation]    Apply a certain resource via kubectl apply -f
    [Arguments]    ${fileOrUrl}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${fileOrUrl}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    [Return]    ${rc}    ${output}

kubectl get
    [Documentation]    Apply a certain resource via kubectl apply -f
    [Arguments]    ${options}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get ${options}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    [Return]    ${rc}    ${output}