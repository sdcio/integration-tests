*** Settings ***
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot


*** Test Cases ***
Install SDCIO
    kubectl apply     ./config-server/artifacts/out/artifacts.yaml

Install CI keyring secret
    [Documentation]    config-server no longer ships a default config-keyring
    ...    Secret in its own deploy artifacts (by design, to force real
    ...    deployments to bring their own key material). The data-server
    ...    StatefulSets mount this Secret as a volume regardless, so CI must
    ...    provision its own throwaway key or the pods hang in
    ...    ContainerCreating forever waiting for a Secret that never exists.
    kubectl apply     ./integration-tests/tests/00-setup/secret-config-keyring.yaml

