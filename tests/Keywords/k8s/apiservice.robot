*** Settings ***
Resource    kubectl.robot


*** Keywords ***
APIService Ready
    [Arguments]    ${APIServiceName}
    ${rc}    ${output} =     kubectl get    apiservices.apiregistration.k8s.io ${APIServiceName} -o=jsonpath='{.status.conditions[0]}'
    Should Contain    ${output}    "status":"True"    msg="API Service not Ready"
    Should Contain    ${output}    "type":"Available"    msg="API Service not Ready"
