*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/config.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
@{SDCIO_SROS_NODES}     sr1    sr2
${operation}            Update
${intent1}              "service-name": "vprn123"
${intent2}              "service-name": "vprn234"
${intent3}              "service-name": "vprn789"
${intent4}              "service-name": "vprn987"
${adminstate}           "admin-state": "disable"
${null}                 "configure/service/vprn": null


*** Test Cases ***
${operation} - ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/sros/intent1-sros-update.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} ConfigSet intent1 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent1-sros"

Verify - ${operation} ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    ${adminstate}

${operation} - ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/sros/intent2-sros-update.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} ConfigSet intent2 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent2-sros"

Verify - ${operation} ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    ${adminstate}

${operation} - Config intent3 on sr1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/sros/intent3-sros-update.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent3 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent3-sros"

Verify - ${operation} Config intent3 on sr1
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    ${adminstate}

${operation} - Config intent4 on sr2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/sros/intent4-sros-update.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent4 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent4-sros"

Verify - ${operation} Config intent4 on sr2
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    ${adminstate}


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

Verify no Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path ${path}
    Log    ${output}
    Should Contain    ${output}    ${intent}

Delete Config on node
    [Documentation]    Delete config from a node using gNMI.
    [Arguments]    ${node}    ${path}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete ${path}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Setup
    Run    echo 'setup executed'
    kubectl apply    ${CURDIR}/sros/customer.yaml
    Wait Until Keyword Succeeds    1min    5s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    kubectl apply    ${CURDIR}/sros/intent1-sros.yaml
    Wait Until Keyword Succeeds    1min    5s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-sros"
    kubectl apply    ${CURDIR}/sros/intent2-sros.yaml
    Wait Until Keyword Succeeds    1min    5s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-sros"
    kubectl apply    ${CURDIR}/sros/intent3-sros.yaml
    Wait Until Keyword Succeeds    1min    5s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    kubectl apply    ${CURDIR}/sros/intent4-sros.yaml
    Wait Until Keyword Succeeds    1min    5s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-sros"

Cleanup
    Run    echo 'cleanup executed'
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-sros"
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-sros"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-sros"
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${null}
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    Run Keyword If Any Tests Failed    Sleep    5s
