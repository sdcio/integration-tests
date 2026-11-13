*** Settings ***
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/data-server-endpoint.robot

Suite Setup         Start Data Server Endpoint Port Forward
Suite Teardown      Stop Data Server Endpoint Port Forward

*** Variables ***
${TARGET}               srl1
${eventual_timeout}     2min
${retry}                2s

*** Test Cases ***
TC1: Controller Container Hosts The Data Server
    [Documentation]    The pod template has the controller container and no data-server sidecar.
    [Tags]    single-container
    ${containers}=    Data Server Controller Pod Containers
    Should Contain    ${containers}    controller
    Should Not Contain    ${containers}    data-server
    ...    msg=data-server sidecar still present: the merged pod must be a single container

TC2: Data Server gRPC Endpoint Is Reachable Via Service
    [Documentation]    svc/data-server:56000 serves DataServer and SchemaServer through a port-forward.
    [Tags]    single-container    port-forward
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Data Server Endpoint Lists Services

TC3: Target Datastore Is Served After The Pod Is Ready
    [Documentation]    The discovered target is Ready and its datastore answers on :56000.
    [Tags]    single-container    port-forward
    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${TARGET}
    Data Server Endpoint Serves Datastore    ${TARGET}

TC4: CLI Reaches The Data Server
    [Documentation]    `kubectl sdc runningconfig` (GetIntent against the data-server) succeeds
    ...    for the target.
    [Tags]    single-container    cli
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    kubectl sdc runningconfig --target ${TARGET} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${output}
