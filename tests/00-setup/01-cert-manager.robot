*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../Keywords/cert-manager.robot
Resource            ../variables.robot

*** Test Cases ***
Install Cert-Manager
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${ CERT_MANAGER_VERSION }/cert-manager.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
