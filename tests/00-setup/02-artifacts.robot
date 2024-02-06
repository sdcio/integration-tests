*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../common.robot
Resource            ../variables.robot
Resource            ../Keywords/config-server.robot


*** Variables ***



*** Test Cases ***
Install SDCIO
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ./config-server/artifacts/out/artifacts.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0


*** Keywords ***
SDCIO Ready
    SDCIO until Config-Server deployment ready

SDCIO until Config-Server deployment ready
    Wait until Config-Server Ready

    

