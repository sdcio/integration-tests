*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../variables.robot

*** Test Cases ***
Install Cert-Manager
    kubectl apply    https://github.com/cert-manager/cert-manager/releases/download/${ CERT_MANAGER_VERSION }/cert-manager.yaml

