*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON


*** Keywords ***
Targets Check Ready
    [Documentation]    Make sure the discovered Targets are ready
    [Arguments]    ${namespace}    ${node}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=json ${node}
    Log     ${output}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=jsonpath='{.status}' ${node}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.conditions[*].status
    Should be equal as strings    ${status}    ['True', 'True', 'True', 'True', 'True']

Target Check Ready With Profiles
    [Documentation]    Make sure the discovered Target is ready and uses the expected connection and sync profiles
    [Arguments]    ${namespace}    ${node}    ${connection_profile}    ${sync_profile}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=json ${node}
    Log     ${output}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[*].status
    Should be equal as strings    ${status}    ['True', 'True', 'True', 'True', 'True']
    ${target_connection_profile} =    Get values from JSON    ${json}    $.spec.connectionProfile
    Should be equal as strings    ${target_connection_profile}    ['${connection_profile}']
    ${target_sync_profile} =    Get values from JSON    ${json}    $.spec.syncProfile
    Should be equal as strings    ${target_sync_profile}    ['${sync_profile}']
