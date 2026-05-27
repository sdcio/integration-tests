*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON

*** Keywords ***
Get Config Deviation Resource Name
    [Documentation]    Returns the canonical Deviation CR name for a given Config CR name.
    ...    config-server names Deviations of type "config" as "config-<config-name>" (see
    ...    apis/config/v1alpha1/deviation_helpers.go: DeviationName), so the test inputs
    ...    (which carry the underlying Config name) need this prefix to address the actual
    ...    Deviation resource on k8s.
    [Arguments]    ${config_name}
    RETURN    config-${config_name}

Verify Deviation on k8s
    [Documentation]    Verify the deviation CR on k8s, check if the deviation counter is increased
    [Arguments]    ${name}    ${match}
    ${deviation_name} =    Get Config Deviation Resource Name    ${name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${deviation_name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    Log    ${output}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get configs.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    Log    ${output}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${deviation_name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json | jq '.spec.deviations // [] | length'
    Log    ${output}
    ${result} =	    Convert To Integer    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal As Integers    ${result}    ${match}

Delete Deviation
    [Documentation]    Delete the deviation CR on k8s
    [Arguments]    ${name}
    ${deviation_name} =    Get Config Deviation Resource Name    ${name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc deviation --deviation ${deviation_name} --revert -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}
