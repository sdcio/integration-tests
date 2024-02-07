*** Settings ***
Library             OperatingSystem


*** Keywords ***
APIService Ready
    [Arguments]    ${APIServiceName}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get apiservices.apiregistration.k8s.io ${APIServiceName} -o=jsonpath='{.status.conditions[0]}'
    Log    ${output}
    Should Contain    ${output}    "status":"True"    msg="API Service not Ready"
    Should Contain    ${output}    "type":"Available"    msg="API Service not Ready"
    Should Be Equal As Integers    ${rc}    0