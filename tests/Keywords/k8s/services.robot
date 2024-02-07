*** Settings ***
Library             OperatingSystem


*** Keywords ***
Endpoints amount of Pods registered
    [Documentation]     Checks the first subset of Endpoints for a given service, that the given min-count-available (default = 1) is present
    [Arguments]    ${namespace}    ${service}    ${min-count-available}=1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get -n ${namespace} endpoints ${service} -o=jsonpath='{.subsets[0].addresses}' | jq 'length'
    Log    ${output}
    ${result} =	    Convert To Integer    ${output}
    Should Be True    ${result} >= ${min-count-available}
    Should Be Equal As Integers    ${rc}    0



