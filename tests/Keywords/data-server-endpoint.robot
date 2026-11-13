*** Settings ***
Resource    ../variables.robot
Library     Process
Library     OperatingSystem
Library     String

*** Variables ***
${DS_ENDPOINT_LOCAL_PORT}    56000
${DS_ENDPOINT_PF_HANDLE}     ${NONE}
${SDC_PROTOS_REPO}           https://github.com/sdcio/sdc-protos.git
${SDC_PROTOS_DIR}            ${OUTPUT DIR}${/}sdc-protos
${GRPCURL_PROTOS}            -import-path ${SDC_PROTOS_DIR} -proto data.proto -proto schema.proto

*** Keywords ***
Fetch Sdc Protos
    [Documentation]    The data-server does not serve gRPC reflection, so grpcurl reads the
    ...    DataServer and SchemaServer definitions from a checkout of sdc-protos.
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${SDC_PROTOS_DIR}${/}data.proto
    IF    ${exists}    RETURN
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    git clone --depth 1 ${SDC_PROTOS_REPO} ${SDC_PROTOS_DIR}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Start Data Server Endpoint Port Forward
    [Documentation]    Port-forward svc/data-server:56000, the endpoint datactl and other sdcpb
    ...    clients use, and wait until it answers gRPC.
    Fetch Sdc Protos
    ${handle}=    Start Process
    ...    kubectl port-forward -n ${SDCIO_SYSTEM_NAMESPACE} svc/data-server ${DS_ENDPOINT_LOCAL_PORT}:56000
    ...    shell=True
    ...    stdout=/tmp/data-server-endpoint-pf.stdout
    ...    stderr=/tmp/data-server-endpoint-pf.stderr
    Set Suite Variable    ${DS_ENDPOINT_PF_HANDLE}    ${handle}
    Wait Until Keyword Succeeds    60s    2s    Data Server Endpoint Lists Services

Stop Data Server Endpoint Port Forward
    IF    $DS_ENDPOINT_PF_HANDLE is None
        RETURN
    END
    Terminate Process    ${DS_ENDPOINT_PF_HANDLE}    kill=True
    Set Suite Variable    ${DS_ENDPOINT_PF_HANDLE}    ${NONE}

Data Server Endpoint Lists Services
    [Documentation]    The endpoint behind the port-forward serves both DataServer and SchemaServer.
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    grpcurl -plaintext ${GRPCURL_PROTOS} localhost:${DS_ENDPOINT_LOCAL_PORT} list
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    data.DataServer
    Should Contain    ${output}    schema.SchemaServer

Data Server Endpoint Serves Datastore
    [Documentation]    GetDataStore for the target's datastore succeeds through the port-forward.
    [Arguments]    ${target}
    ${datastore}=    Catenate    SEPARATOR=.    ${SDCIO_RESOURCE_NAMESPACE}    ${target}
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    grpcurl -plaintext ${GRPCURL_PROTOS} -d '{"datastoreName":"${datastore}"}' localhost:${DS_ENDPOINT_LOCAL_PORT} data.DataServer/GetDataStore
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${datastore}

Data Server Controller Pod Containers
    [Documentation]    Container names of the data-server-controller pod template, as a list. The
    ...    controller embeds the data-server when the list is just [controller]; the older
    ...    two-container pod adds a data-server sidecar.
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    kubectl get statefulset ${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE} -o jsonpath='{.spec.template.spec.containers[*].name}'
    Should Be Equal As Integers    ${rc}    0
    @{names}=    Split String    ${output}
    RETURN    ${names}
