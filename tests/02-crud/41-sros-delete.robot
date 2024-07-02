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
${operation}            Delete
${null}                 "configure/service/vprn": null


*** Test Cases ***
${operation} - ConfigSet intent1 on ${SDCIO_SROS_NODES}
    ${rc}    ${output} =    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-sros"

Verify - ${operation} ConfigSet intent1 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Run Keyword And Expect Error    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev intent1-sros

Verify - ${operation} ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no ConfigSet on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}

${operation} - ConfigSet intent2 on ${SDCIO_SROS_NODES}
    ${rc}    ${output} =    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-sros"

Verify - ${operation} ConfigSet intent2 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Run Keyword And Expect Error    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev intent2-sros

Verify - ${operation} ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no ConfigSet on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}

${operation} - Config intent3 on sr1
    ${rc}    ${output} =    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"

Verify - ${operation} Config intent3 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Run Keyword And Expect Error    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev intent3-sros

Verify - ${operation} Config intent3 on sr1
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${null}

${operation} - Config intent4 on sr2
    ${rc}    ${output} =    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-sros"

Verify - ${operation} Config intent4 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Run Keyword And Expect Error    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev intent4-sros

Verify - ${operation} Config intent4 on sr2
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${null}


*** Keywords ***
Verify no ConfigSet on nodes
    [Documentation]    Iterates through the SDCIO_SROS_NODES, validates if the output contains $intent and $adminstate for gNMI $path
    [Arguments]    ${path}    ${intent}
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Verify no Config on node    ${node}    ${path}    ${intent}
    END

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
    Log ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Setup
    Run    echo 'setup executed'
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
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${sr1}
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${sr2}
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${sr1}
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${sr2}
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${sr1}
    ...    "/configure/service/vprn[service-name=vprn789]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${sr2}
    ...    "/configure/service/vprn[service-name=vprn987]"
    Run Keyword If Any Tests Failed    Sleep    5s
