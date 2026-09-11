*** Settings ***
Resource    ../variables.robot
Library     Process
Library     OperatingSystem

*** Variables ***
${DATA_SERVER_GRPC_LOCAL_PORT}    56000
${DATA_SERVER_PF_HANDLE}          ${NONE}
${DATA_SERVER_PF_STARTED}         ${FALSE}

*** Keywords ***
Ensure Data Server gRPC Port Forward
    [Documentation]    Port-forward the data-server gRPC service once per suite so
    ...    GetIntent can be exercised directly (kubectl sdc has no named-intent read).
    IF    ${DATA_SERVER_PF_STARTED}
        RETURN
    END
    ${handle}=    Start Process
    ...    kubectl port-forward -n ${SDCIO_SYSTEM_NAMESPACE} svc/data-server ${DATA_SERVER_GRPC_LOCAL_PORT}:56000
    ...    shell=True
    ...    stdout=/tmp/data-server-pf.stdout
    ...    stderr=/tmp/data-server-pf.stderr
    Set Suite Variable    ${DATA_SERVER_PF_HANDLE}    ${handle}
    Set Suite Variable    ${DATA_SERVER_PF_STARTED}    ${TRUE}
    Wait Until Keyword Succeeds    30s    1s    Data Server gRPC Port Forward Ready

Data Server gRPC Port Forward Ready
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    grpcurl -plaintext localhost:${DATA_SERVER_GRPC_LOCAL_PORT} list data.DataServer
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    GetIntent

Stop Data Server gRPC Port Forward
    IF    not ${DATA_SERVER_PF_STARTED}
        RETURN
    END
    Terminate Process    ${DATA_SERVER_PF_HANDLE}    kill=True
    Set Suite Variable    ${DATA_SERVER_PF_HANDLE}    ${NONE}
    Set Suite Variable    ${DATA_SERVER_PF_STARTED}    ${FALSE}

Get Intent Output Via gRPC
    [Documentation]    Call data.DataServer/GetIntent for a named intent. Under
    ...    Cache.Type: config-server this reads last-applied blobs through
    ...    ConfigReadService and assembles them via mergeConfigBlobs.
    [Arguments]    ${target}    ${intent_name}
    Ensure Data Server gRPC Port Forward
    ${datastore}=    Catenate    SEPARATOR=.    ${SDCIO_RESOURCE_NAMESPACE}    ${target}
    ${request}=    Set Variable    {"datastoreName":"${datastore}","intent":"${intent_name}","format":1}
    ${rc}    ${output}=    Run And Return Rc And Output
    ...    grpcurl -plaintext -d '${request}' localhost:${DATA_SERVER_GRPC_LOCAL_PORT} data.DataServer/GetIntent
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${output}

Verify Intent Get Contains Description
    [Documentation]    Named-intent GetIntent seam: exercises IntentGet →
    ...    NewImportAdapter → mergeConfigBlobs for config-server root blobs.
    [Arguments]    ${target}    ${intent_name}    ${expected_description}
    ${output}=    Get Intent Output Via gRPC    ${target}    ${intent_name}
    Should Contain    ${output}    ${expected_description}
