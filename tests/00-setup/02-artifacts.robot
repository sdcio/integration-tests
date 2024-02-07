*** Settings ***
Library             OperatingSystem
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot


*** Test Cases ***
Install SDCIO
    kubectl apply     ./config-server/artifacts/out/artifacts.yaml

