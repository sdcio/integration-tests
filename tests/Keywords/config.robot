*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON


*** Keywords ***
Config Check Ready
    [Documentation]    Make sure the referenced Config is applied properly
    [Arguments]    ${namespace}    ${object}

    ${rc}    ${output} =    kubectl get    -n ${namespace} configs.config.sdcio.dev -o=json ${object}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[*].status
    Should be equal as strings    ${status}    ['True']

ConfigSet Check Ready
    [Documentation]    Make sure the referenced ConfigSet is applied properly
    [Arguments]    ${namespace}    ${object}

    ${rc}    ${output} =    kubectl get    -n ${namespace} configsets.config.sdcio.dev -o=json ${object}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[*].status
    Should be equal as strings    ${status}    ['True']

Delete Config
    [Documentation]    Make sure the referenced Config is deleted properly
    [Arguments]    ${namespace}    ${object}

    ${rc}    ${output} =    kubectl delete    -n ${namespace} --wait=true configs.config.sdcio.dev ${object}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Delete ConfigSet
    [Documentation]    Make sure the referenced Config is deleted properly
    [Arguments]    ${namespace}    ${object}

    ${rc}    ${output} =    kubectl delete    -n ${namespace} --wait=true configsets.config.sdcio.dev ${object}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}
