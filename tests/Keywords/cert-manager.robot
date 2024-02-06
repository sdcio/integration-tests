*** Settings ***
Resource     deployments.robot

*** Keywords ***
Wait until Cert-Manger Ready
    Cert-Manager until cert-manager deployment ready
    Cert-Manager until cert-manager-cainjector deployment ready
    Cert-Manager until cert-manager-webhook deployment ready
    
Cert-Manager until cert-manager deployment ready
    Wait Until Keyword Succeeds    2 min    2 sec  Deployment AvailableReplicas    cert-manager    cert-manager

Cert-Manager until cert-manager-cainjector deployment ready
    Wait Until Keyword Succeeds    2 min    2 sec    Deployment AvailableReplicas    cert-manager    cert-manager-cainjector

Cert-Manager until cert-manager-webhook deployment ready
    Wait Until Keyword Succeeds    2 min    2 sec    Deployment AvailableReplicas    cert-manager    cert-manager-webhook

