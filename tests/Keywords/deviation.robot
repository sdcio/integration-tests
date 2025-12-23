*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON

*** Keywords ***
Verify Deviation on k8s
    [Documentation]    Verify the deviation CR on k8s, check if the deviation counter is increased
    [Arguments]    ${name}    ${match}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    Log    ${output}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get configs.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    Log    ${output}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json | jq '.spec.deviations // [] | length'
    Log    ${output}
    ${result} =	    Convert To Integer    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal As Integers    ${result}    ${match}

Delete Deviation CR
    [Documentation]    Delete the deviation CR on k8s
    [Arguments]    ${name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete deviation.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}