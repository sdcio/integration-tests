*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
@{SDCIO_SROS_NODES}     sr1    sr2
${operation}            Create
${intent1}              "service-name": "vprn123"
${intent2}              "service-name": "vprn234"
${intent3}              "service-name": "vprn789"
${intent4}              "service-name": "vprn987"
${adminstate}           "admin-state": "enable"


*** Test Cases ***
${operation} - ConfigSet intent1 on ${SDCIO_SROS_NODES}
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/intent1-sros.yaml

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
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/intent2-sros.yaml

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
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/intent3-sros.yaml

Verify - ${operation} ConfigSet intent3 on k8s
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
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/intent4-sros.yaml

Verify - ${operation} ConfigSet intent4 on k8s
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

Setup
    Run    echo 'setup executed'
    Wait Until Keyword Succeeds    15min    5s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    sr1
    Wait Until Keyword Succeeds    15min    5s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    sr2

Cleanup
    Run    echo 'cleanup executed'
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-sros"
    Sleep    2s
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-sros"
    Sleep    2s
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    Sleep    2s
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-sros"
    Sleep    5s
    Run
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn123]"
    Run
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn234]"
    Run
    ...    gnmic -a ${sr1} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn789]"
    Run
    ...    gnmic -a ${sr2} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete "/configure/service/vprn[service-name=vprn987]"
    Sleep    5s
