*** Settings ***
Resource     k8s/deployments.robot
Resource     k8s/kubectl.robot
Resource     ../variables.robot
Resource    k8s/apiservice.robot
Resource    k8s/services.robot
Library    String
Library    OperatingSystem


*** Keywords ***
Wait until Config-Server Ready
    [Documentation]     Aggregated check for the availability of the Config Server
    Config-Server until config-Server deployment ready
    Config-Server until Service Endpoints
    Config-Server until APIService ready
    Config-Server until data-server-controller StatefulSet ready

Config-Server until data-server-controller StatefulSet ready
    [Documentation]    Schema CRs (suite 01) need gRPC to schema-server:56000; that is the data-server container in this StatefulSet. Not covered by api-server Deployment checks above.
    ${ready}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    10 min    5 sec    StatefulSet Ready Replicas    ${SDCIO_SYSTEM_NAMESPACE}    ${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET}
    IF    not ${ready}
        Log data-server-controller diagnostics
        Fail    data-server-controller StatefulSet not ready within 10m (schema-server gRPC / suite 01 depends on this)
    END

Log data-server-controller diagnostics
    [Documentation]    Best-effort kubectl snapshot when data-server-controller fails readiness (logs at WARN).
    Log    === data-server-controller / schema-server diagnostics ===    WARN
    Kubectl log diagnostic    get statefulset ${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE} -o wide
    Kubectl log diagnostic    get pods -n ${SDCIO_SYSTEM_NAMESPACE} -l app.kubernetes.io/name=sdc-data-server-controller -o wide
    Kubectl log diagnostic    describe statefulset ${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE}
    Kubectl log diagnostic    get endpointslices -n ${SDCIO_SYSTEM_NAMESPACE} -l kubernetes.io/service-name=schema-server -o wide
    Kubectl log diagnostic    get endpoints schema-server -n ${SDCIO_SYSTEM_NAMESPACE} -o yaml
    Kubectl log diagnostic    logs statefulset/${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE} -c data-server --tail=400
    Kubectl log diagnostic    logs statefulset/${SDCIO_DATA_SERVER_CONTROLLER_STATEFULSET} -n ${SDCIO_SYSTEM_NAMESPACE} -c controller --tail=250

Config-Server until config-Server deployment ready
    [Documentation]     Will wait for the Colocated Deployment to become available
    Wait Until Keyword Succeeds    3 min    2 sec  Deployment AvailableReplicas    ${SDCIO_SYSTEM_NAMESPACE}    ${SDCIO_COLOCATED_DEPLOYMENT}

Config-Server until Service Endpoints
    [Documentation]    Checks that the Servie endpoints are registered for the API Aggregation Service
    Wait Until Keyword Succeeds    1 min    2 sec    Endpoints amount of Pods registered    ${SDCIO_SYSTEM_NAMESPACE}    ${SDCIO_COLOCATED_DEPLOYMENT}

Config-Server until APIService ready
    [Documentation]     Will wait for all the SDCIO_APIServices defined in the variables file to become available.
    FOR    ${s}    IN     @{SDCIO_APIServices}
        Wait Until Keyword Succeeds    1 min    2 sec    APIService Ready    ${s}
    END

Collect Pod Logs By Label
    [Arguments]    ${namespace}    ${log_dir}

    Create Directory    ${log_dir}

    ${rc}    ${pods}=    Run And Return Rc And Output
    ...    kubectl get pods -n ${namespace} -l app.kubernetes.io/name=config-server -o name

    Run Keyword If    '${pods}' == ''    Log    No config-server pods found    WARN

    @{pod_list}=    Split To Lines    ${pods}

    FOR    ${pod}    IN    @{pod_list}
        Collect Logs For Pod Containers    ${pod}    ${namespace}    ${log_dir}
    END

Collect Logs For Pod Containers
    [Arguments]    ${pod}    ${namespace}    ${log_dir}

    ${rc}    ${containers}=    Run And Return Rc And Output
    ...    kubectl get ${pod} -n ${namespace} -o jsonpath={.spec.containers[*].name}

    @{container_list}=    Split String    ${containers}

    FOR    ${container}    IN    @{container_list}
        ${rc}    ${logs}=    Run And Return Rc And Output
        ...    kubectl logs ${pod} -n ${namespace} -c ${container} --timestamps

        ${safe_pod}=    Replace String    ${pod}    /    _
        Create File
        ...    ${log_dir}/${safe_pod}_${container}.log
        ...    ${logs}
    END