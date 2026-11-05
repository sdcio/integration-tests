*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON


*** Keywords ***
Targets Check Ready
    [Documentation]    Make sure the discovered Targets are ready
    [Arguments]    ${namespace}    ${node}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=json ${node}
    Log     ${output}
    ${json} =    Convert string to JSON    ${output}
    Target Conditions Should Be Ready    ${json}

Target Check Ready With Profiles
    [Documentation]    Make sure the discovered Target is ready and uses the expected connection and sync profiles
    [Arguments]    ${namespace}    ${node}    ${connection_profile}    ${sync_profile}
    ${rc}    ${output} =    kubectl get    -n ${namespace} targets.config.sdcio.dev -o=json ${node}
    Log     ${output}
    ${json} =    Convert string to JSON    ${output}
    Target Conditions Should Be Ready    ${json}
    ${target_connection_profile} =    Get values from JSON    ${json}    $.spec.connectionProfile
    Should be equal as strings    ${target_connection_profile}    ['${connection_profile}']
    ${target_sync_profile} =    Get values from JSON    ${json}    $.spec.syncProfile
    Should be equal as strings    ${target_sync_profile}    ['${sync_profile}']

Target Conditions Should Be Ready
    [Documentation]    Asserts the Target carries exactly the Ready and TargetDiscoveryReady conditions, both True.
    ...    Ready reports overall health; TargetDiscoveryReady is the discovery stage. A failing stage is
    ...    indicated by the condition that is not True.
    [Arguments]    ${target_json}
    ${types} =    Get values from JSON    ${target_json}    $.status.conditions[*].type
    ${sorted_types} =    Evaluate    sorted($types)
    Should Be Equal As Strings    ${sorted_types}    ['Ready', 'TargetDiscoveryReady']
    ...    msg=Unexpected Target condition types
    FOR    ${type}    IN    Ready    TargetDiscoveryReady
        ${status} =    Get values from JSON    ${target_json}    $.status.conditions[?(@.type=='${type}')].status
        Should Be Equal As Strings    ${status}    ['True']
        ...    msg=Target condition ${type} is not True
    END
