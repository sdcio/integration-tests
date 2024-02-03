*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../common.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
${lab-name}         01-crud


*** Test Cases ***
Deploy ${lab-name} intent1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent1-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

*** Keywords ***
Setup
    Run    echo 'setup executed'

Cleanup
    Run    echo 'cleanup executed'
    Run    gnmic -a 172.21.1.11 -p 57400 --insecure -u admin -p admin set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    gnmic -a 172.21.1.12 -p 57400 --insecure -u admin -p admin set --delete "/configure/service/vprn[service-name=vprn123]"
