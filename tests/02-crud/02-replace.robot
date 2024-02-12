*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
@{SDCIO_SROS_NODES}     sr1    sr2
${operation}            Replace
${intent1-orig}         "service-name": "vprn123"
${intent2-orig}         "service-name": "vprn234"
${intent3-orig}         "service-name": "vprn789"
${intent4-orig}         "service-name": "vprn987"
${intent1}              "service-name": "vprn1123"
${intent2}              "service-name": "vprn1234"
${intent3}              "service-name": "vprn1789"
${intent4}              "service-name": "vprn1987"
${adminstate}           "admin-state": "enable"


*** Test Cases ***
${operation} - ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent1-sros-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn1123]"
    ...    ${intent1}
    ...    ${adminstate}

Verify - ${operation} ConfigSet intent1 on ${SDCIO_SROS_NODES} no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet does not exist on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1-orig}

${operation} - ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent2-sros-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn1234]"
    ...    ${intent2}
    ...    ${adminstate}

Verify - ${operation} ConfigSet intent2 on ${SDCIO_SROS_NODES} no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet does not exist on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2-orig}

${operation} - Config intent3 on sr1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent3-sros-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent3 on sr1
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn1789]"
    ...    ${intent3}
    ...    ${adminstate}

Verify - ${operation} Config intent3 on sr1 no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config does not exist on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3-orig}

${operation} - Config intent4 on sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/intent4-sros-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent4 on sr2
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn1987]"
    ...    ${intent4}
    ...    ${adminstate}

Verify - ${operation} Config intent4 on sr2 no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config does not exist on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4-orig}


*** Keywords ***
Verify ConfigSet intent on nodes
    [Documentation]    Iterates through the SDCIO_SROS_NODES, validates if the output contains $intent and $adminstate for gNMI $path
    [Arguments]    ${path}    ${intent}    ${adminstate}
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Verify Config on node    ${node}    ${path}    ${intent}    ${adminstate}
    END

Verify Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}    ${adminstate}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path ${path}
    Log    ${output}
    Should Contain    ${output}    ${intent}
    Should Contain    ${output}    ${adminstate}

Verify ConfigSet does not exist on nodes
    [Documentation]    Iterates through the SDCIO_SROS_NODES, validates if the output does not contains $intent for gNMI $path
    [Arguments]    ${path}    ${intent}
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Verify Config does not exist on node    ${node}    ${path}    ${intent}
    END

Verify Config does not exist on node
    [Documentation]    Validate if Config does not exist on a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path ${path}
    Log    ${output}
    Should Not Contain    ${output}    ${intent}

Setup
    Run    echo 'setup executed'
    Run    kubectl apply -f ${CURDIR}/intent1-sros.yaml
    Run    kubectl apply -f ${CURDIR}/intent2-sros.yaml
    Run    kubectl apply -f ${CURDIR}/intent3-sros.yaml
    Run    kubectl apply -f ${CURDIR}/intent4-sros.yaml
    Sleep    5s

Cleanup
    Run    echo 'cleanup executed'
    Run    kubectl delete -f ${CURDIR}/intent1-sros-replace.yaml
    Run
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn1123]"
    Run
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn1123]"
    Run    kubectl delete -f ${CURDIR}/intent2-sros-replace.yaml
    Run
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn1234]"
    Run
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn1234]"
    Run    kubectl delete -f ${CURDIR}/intent3-sros-replace.yaml
    Run
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn1789]"
    Run    kubectl delete -f ${CURDIR}/intent4-sros-replace.yaml
    Run
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn1987]"
    Sleep    10s
