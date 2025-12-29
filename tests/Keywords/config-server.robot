*** Settings ***
Resource     k8s/deployments.robot
Resource     ../variables.robot
Resource    k8s/apiservice.robot
Resource    k8s/services.robot
Library    String


*** Keywords ***
Wait until Config-Server Ready
    [Documentation]     Aggregated check for the availability of the Config Server
    Config-Server until config-Server deployment ready
    Config-Server until Service Endpoints
    Config-Server until APIService ready

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