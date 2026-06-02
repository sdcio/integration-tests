*** Settings ***
Library     OperatingSystem


*** Keywords ***
kubectl apply
    [Documentation]    Apply a certain resource via kubectl apply -f
    [Arguments]    ${fileOrUrl}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${fileOrUrl}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

kubectl get
    [Documentation]    Get a certain resource via kubectl get
    [Arguments]    ${options}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get ${options}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

kubectl delete
    [Documentation]    Delete a certain resource via kubectl delete
    [Arguments]    ${options}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete ${options}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

kubectl patch
    [Documentation]    Patch a certain resource via kubectl patch
    [Arguments]    ${resource}    ${resource_name}    ${patch}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl patch ${resource} ${resource_name} -p ${patch} --type='merge'
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Kubectl log diagnostic
    [Documentation]    Run `kubectl` with the rest of the CLI (everything after the word kubectl). Logs at WARN; does not fail on non-zero exit (for CI troubleshooting).
    [Arguments]    ${kubectl_arguments}
    ${rc}    ${output} =    Run And Return Rc And Output    kubectl ${kubectl_arguments}
    Log    DIAG: kubectl ${kubectl_arguments}\nrc=${rc}\n${output}    WARN
