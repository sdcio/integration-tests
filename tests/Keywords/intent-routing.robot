*** Settings ***
Library             Collections
Resource            config.robot
Resource            yq.robot
Resource            k8s/kubectl.robot

*** Variables ***
${eventual_timeout}    2min
${retry}               10s

*** Keywords ***
Initialize Intent Target Cache
    [Documentation]    Build a cache mapping each intent to its target node (or "ALL" for ConfigSets).
    ...    Arguments:
    ...      input_dir     — absolute path to the directory holding intent YAML files (e.g. ${CURDIR}/input/sros)
    ...      intent_suffix — filename suffix identifying the platform (e.g. -sros or -srl)
    [Arguments]    ${input_dir}    ${intent_suffix}
    @{all_intents} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}
    &{cache} =    Create Dictionary
    FOR    ${intent}    IN    @{all_intents}
        ${is_configset} =    Run Keyword And Return Status
        ...    List Should Contain Value    ${SDCIO_CONFIGSET_INTENTS}    ${intent}
        IF    ${is_configset}
            Set To Dictionary    ${cache}    ${intent}=ALL
        ELSE
            ${rc}    ${targetdevice} =    YQ file
            ...    ${input_dir}/${intent}${intent_suffix}.yaml
            ...    '.metadata.labels."config.sdcio.dev/targetName"'
            Should Be Equal As Integers    ${rc}    0
            Set To Dictionary    ${cache}    ${intent}=${targetdevice}
        END
    END
    Set Suite Variable    ${INTENT_TARGET_CACHE}    ${cache}

Get Target Nodes For Intent
    [Documentation]    Return the list of nodes that an intent targets.
    ...    ConfigSet intents return all_nodes; Config intents return a single-element list.
    [Arguments]    ${intent}    ${all_nodes}
    ${target_mode} =    Get From Dictionary    ${INTENT_TARGET_CACHE}    ${intent}
    IF    '${target_mode}' == 'ALL'
        RETURN    @{all_nodes}
    END
    @{targetnodes} =    Create List    ${target_mode}
    RETURN    @{targetnodes}

Apply Intent On K8s
    [Documentation]    Apply an intent YAML and wait for the k8s resource to reach Ready state.
    ...    Arguments:
    ...      intent       — intent name (e.g. intent1)
    ...      file_suffix  — file-name suffix after the name_suffix (e.g. ${EMPTY}, -update, -replace)
    ...      input_dir    — path to directory holding intent YAML files
    ...      name_suffix  — platform suffix used in the k8s resource name (e.g. -sros, -srl)
    [Arguments]    ${intent}    ${file_suffix}    ${input_dir}    ${name_suffix}
    ${rc}    ${output} =    kubectl apply    ${input_dir}/${intent}${name_suffix}${file_suffix}.yaml
    IF    $intent in $SDCIO_CONFIGSET_INTENTS
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}${name_suffix}
    ELSE
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}${name_suffix}
    END

Delete Intent From K8s
    [Documentation]    Delete an intent from k8s and wait until the resource is gone.
    ...    Arguments:
    ...      intent      — intent name (e.g. intent1)
    ...      name_suffix — platform suffix used in the k8s resource name (e.g. -sros, -srl)
    [Arguments]    ${intent}    ${name_suffix}
    IF    $intent in $SDCIO_CONFIGSET_INTENTS
        ${rc}    ${output} =    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}${name_suffix}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}${name_suffix}
    ELSE
        ${rc}    ${output} =    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}${name_suffix}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}${name_suffix}
    END
