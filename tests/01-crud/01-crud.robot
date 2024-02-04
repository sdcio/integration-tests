*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../common.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
${lab-name}         01-crud
${intent1}          vprn[service-name=vprn123]
${intent2}          vprn[service-name=vprn234]
${adminstate}       "admin-state": "enable"

*** Test Cases ***
Deploy ${lab-name} ConfigSet intent1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent1-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify ${lab-name} ConfigSet intent1 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a 172.21.1.11 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn123]"
    Log    ${output}
    Should Contain    ${output}    ${intent1}
    Should Contain    ${output}    ${adminstate}
    #Should Be Equal As Strings    ${output}    ${n2-ipv6}

Verify ${lab-name} ConfigSet intent1 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a 172.21.1.12 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn123]"
    Log    ${output}
    Should Contain    ${output}    ${intent1}
    Should Contain    ${output}    ${adminstate}
    #Should Be Equal As Strings    ${output}    ${n2-ipv6}

Deploy ${lab-name} ConfigSet intent2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent2-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify ${lab-name} ConfigSet intent2 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a 172.21.1.11 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn234]"
    Log    ${output}
    Should Contain    ${output}    ${intent2}
    Should Contain    ${output}    ${adminstate}

Verify ${lab-name} ConfigSet intent2 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a 172.21.1.12 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn234]"
    Log    ${output}
    Should Contain    ${output}    ${intent2}
    Should Contain    ${output}    ${adminstate}

*** Keywords ***
Setup
    Run    echo 'setup executed'

Cleanup
    Run    echo 'cleanup executed'
    Run    gnmic -a 172.21.1.11 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    gnmic -a 172.21.1.12 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    gnmic -a 172.21.1.11 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run    gnmic -a 172.21.1.12 -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
