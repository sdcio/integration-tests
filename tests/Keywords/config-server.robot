*** Settings ***
Resource     k8s/deployments.robot
Resource     ../variables.robot
Resource    k8s/apiservice.robot
Resource    k8s/services.robot

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