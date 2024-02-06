*** Settings ***
Resource     deployments.robot
Resource     ../variables.robot

*** Keywords ***
Wait until Config-Server Ready
    Config-Server until config-Server deployment ready

Config-Server until config-Server deployment ready
    Wait Until Keyword Succeeds    2 min    2 sec  Deployment AvailableReplicas    ${SDCIO_NAMESPACE}    ${SDCIO_COLOCATED_DEPLOYMENT}
