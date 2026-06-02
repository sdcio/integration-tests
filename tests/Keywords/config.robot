*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON


*** Keywords ***
Config Check Ready
    [Documentation]    Make sure the referenced Config is applied properly
    [Arguments]    ${namespace}    ${object}

    ${rc}    ${output} =    kubectl get    -n ${namespace} configs.config.sdcio.dev -o=json ${object}
    Log    ${output}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[?(@.type=='Ready')].status
    Should be equal as strings    ${status}    ['True']

ConfigSet Check Ready
    [Documentation]    Make sure the referenced ConfigSet is applied properly
    [Arguments]    ${namespace}    ${object}

    ${rc}    ${output} =    kubectl get    -n ${namespace} configsets.config.sdcio.dev -o=json ${object}
    Log    ${output}
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[?(@.type=='Ready')].status
    Should be equal as strings    ${status}    ['True']

Delete Config
    [Documentation]    Make sure the referenced Config is deleted properly
    [Arguments]    ${namespace}    ${object}
    # Bounded wait: without --timeout, kubectl can block until API server / finalizers
    # complete (see e.g. intent4-sros teardown: validation errors holding finalizer).
    ${delete_opts}=    Set Variable    -n ${namespace} configs.config.sdcio.dev ${object} --timeout=15m
    ${rc}    ${output} =    kubectl delete    ${delete_opts}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Delete ConfigSet
    [Documentation]    Make sure the referenced Config is deleted properly
    [Arguments]    ${namespace}    ${object}
    # Same rationale as Delete Config: avoid unbounded kubectl wait on stuck finalizers.
    ${delete_opts}=    Set Variable    -n ${namespace} configsets.config.sdcio.dev ${object} --timeout=15m
    ${rc}    ${output} =    kubectl delete    ${delete_opts}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}
