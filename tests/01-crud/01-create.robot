*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../common.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
${lab-name}         01-crud
${intent1}          "service-name": "vprn123"
${intent2}          "service-name": "vprn234"
${intent3}          "service-name": "vprn789"
${intent4}          "service-name": "vprn987"
${adminstate}       "admin-state": "enable"

*** Test Cases ***
Deploy ${lab-name} ConfigSet intent1 on sr1,sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent1-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Verify ${lab-name} ConfigSet intent1 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn123]"
    Log    ${output}
    Should Contain    ${output}    ${intent1}
    Should Contain    ${output}    ${adminstate}
    #Should Be Equal As Strings    ${output}    ${n2-ipv6}

Verify ${lab-name} ConfigSet intent1 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn123]"
    Log    ${output}
    Should Contain    ${output}    ${intent1}
    Should Contain    ${output}    ${adminstate}
    #Should Be Equal As Strings    ${output}    ${n2-ipv6}

Deploy ${lab-name} ConfigSet intent2 on sr1,sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent2-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Verify ${lab-name} ConfigSet intent2 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn234]"
    Log    ${output}
    Should Contain    ${output}    ${intent2}
    Should Contain    ${output}    ${adminstate}

Verify ${lab-name} ConfigSet intent2 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn234]"
    Log    ${output}
    Should Contain    ${output}    ${intent2}
    Should Contain    ${output}    ${adminstate}

Deploy ${lab-name} Config intent3 on sr1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent3-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Verify ${lab-name} Config intent3 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn789]"
    Log    ${output}
    Should Contain    ${output}    ${intent3}
    Should Contain    ${output}    ${adminstate}

Deploy ${lab-name} Config intent4 on sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent4-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Verify ${lab-name} Config intent4 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn987]"
    Log    ${output}
    Should Contain    ${output}    ${intent4}
    Should Contain    ${output}    ${adminstate}

*** Keywords ***
Setup
    Run    echo 'setup executed'

Cleanup
    Run    echo 'cleanup executed'
    Run    kubectl delete -f ${CURDIR}/intent1-sros.yaml
    Run    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    kubectl delete -f ${CURDIR}/intent2-sros.yaml
    Run    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run    kubectl delete -f ${CURDIR}/intent3-sros.yaml
    Run    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn789]"
    Run    kubectl delete -f ${CURDIR}/intent4-sros.yaml
    Run    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn987]"
    Sleep  10s
