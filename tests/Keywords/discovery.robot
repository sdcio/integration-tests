*** Settings ***
Library     OperatingSystem
Resource    ../variables.robot
Resource    k8s/kubectl.robot


*** Keywords ***
Apply Discovery Rules
    [Arguments]    @{rule_files}
    FOR    ${rule_file}    IN    @{rule_files}
        kubectl apply    ${rule_file}
    END

Delete Discovery Rules If Present
    [Arguments]    @{rule_names}
    FOR    ${rule_name}    IN    @{rule_names}
        ${rc}    ${output} =    Run And Return Rc And Output
        ...    kubectl get -n ${SDCIO_RESOURCE_NAMESPACE} discoveryrules.inv.sdcio.dev ${rule_name}
        IF    ${rc} == 0
            ${rc}    ${output} =    Run And Return Rc And Output
            ...    kubectl delete -n ${SDCIO_RESOURCE_NAMESPACE} discoveryrules.inv.sdcio.dev ${rule_name}
            Log    ${output}
            Should Be Equal As Integers    ${rc}    0
        END
    END