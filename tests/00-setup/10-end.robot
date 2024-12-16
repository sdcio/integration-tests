*** Settings ***
Resource    ../Keywords/config-server.robot
Resource    ../Keywords/cert-manager.robot

*** Test Cases ***
Wait for all resources ready
    Wait until Cert-Manger Ready
    Wait until Config-Server Ready
