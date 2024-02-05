*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../common.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
${lab-name}         01-crud
${null}             "configure/service/vprn": null

*** Test Cases ***
Remove - ${lab-name} ConfigSet intent1 on sr1,sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete -f ${CURDIR}/intent1-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Remove - verify ${lab-name} ConfigSet intent1 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn123]"
    Log    ${output}
    Should Contain    ${output}    ${null}

Remove - verify ${lab-name} ConfigSet intent1 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn123]"
    Log    ${output}
    Should Contain    ${output}    ${null}

Remove - ${lab-name} ConfigSet intent2 on sr1,sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete -f ${CURDIR}/intent2-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Remove - verify ${lab-name} ConfigSet intent2 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn234]"
    Log    ${output}
    Should Contain    ${output}    ${null}

Remove - verify ${lab-name} ConfigSet intent2 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn234]"
    Log    ${output}
    Should Contain    ${output}    ${null}

Remove - ${lab-name} ConfigSet intent3 on sr1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete -f ${CURDIR}/intent3-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Remove - verify ${lab-name} ConfigSet intent3 on sr1
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn789]"
    Log    ${output}
    Should Contain    ${output}    ${null}

Remove - ${lab-name} ConfigSet intent4 on sr1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete -f ${CURDIR}/intent4-sros.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Sleep  5s

Remove - verify ${lab-name} ConfigSet intent4 on sr2
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path "/configure/service/vprn[service-name=vprn987]"
    Log    ${output}
    Should Contain    ${output}    ${null}

*** Keywords ***
Setup
    Run    echo 'setup executed'
    Run    kubectl apply -f ${CURDIR}/intent1-sros.yaml
    Run    kubectl apply -f ${CURDIR}/intent2-sros.yaml
    Run    kubectl apply -f ${CURDIR}/intent3-sros.yaml
    Run    kubectl apply -f ${CURDIR}/intent4-sros.yaml
    Sleep  5s

Cleanup
    Run    echo 'cleanup executed'
    Run    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn789]"
    Run    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn987]"
    Sleep  10s
