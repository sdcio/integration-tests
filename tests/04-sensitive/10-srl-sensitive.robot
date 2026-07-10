*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Library             RPA.JSON
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/deviation.robot
Resource            ../Keywords/config-server.robot
Resource            ../Keywords/gnmic.robot

Suite Setup         Setup
Suite Teardown      Cleanup

*** Variables ***
# Intent 1 – srl1, two secrets, ethernet-1/6 and ethernet-1/7
${INTENT1_NAME}         intent-sensitive-srl-1
${INTENT1_TARGET}       srl1
${INTENT1_IFACE_A}      ethernet-1/6
${INTENT1_IFACE_B}      ethernet-1/7
${INTENT1_SECRET_A}     sensitive-1a
${INTENT1_SECRET_B}     sensitive-1b
${SECRET_VALUE_1A}      secret-value-1a
${SECRET_VALUE_1B}      secret-value-1b

# Intent 2 – srl1, two secrets, ethernet-1/8 and ethernet-1/9
${INTENT2_NAME}         intent-sensitive-srl-2
${INTENT2_TARGET}       srl1
${INTENT2_IFACE_A}      ethernet-1/8
${INTENT2_IFACE_B}      ethernet-1/9
${INTENT2_SECRET_A}     sensitive-2a
${INTENT2_SECRET_B}     sensitive-2b
${SECRET_VALUE_2A}      secret-value-2a
${SECRET_VALUE_2B}      secret-value-2b

${SENSITIVE_REDACTED}   ***
${options}              --skip-verify -e PROTO
${optionsSet}           --skip-verify -e JSON_IETF
${eventual_timeout}     2min
${retry}                2s

*** Test Cases ***
TC1: Apply Both Sensitive Configs And Verify K8s Pipeline
    [Documentation]    Both Config CRs are Ready; specs retain their var placeholders; SensitiveConfigs
    ...    carry non-empty encrypted payloads; TargetSnapshot records both intents.
    [Tags]    happy-path
    FOR    ${name}    IN    ${INTENT1_NAME}    ${INTENT2_NAME}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${name}
        Verify Config Spec Retains Placeholders    ${name}
        Verify Sensitive Config Payload Non Empty    ${name}
        Verify Target Snapshot Contains Intent    ${name}
    END

TC2: Verify Device Has All Four Resolved Secret Values
    [Documentation]    All four interface descriptions on the device carry the actual plaintext
    ...    secret values (not redacted) for both intents.
    [Tags]    happy-path
    Verify Interface Description On Device    ${INTENT1_TARGET}    ${INTENT1_IFACE_A}    ${SECRET_VALUE_1A}
    Verify Interface Description On Device    ${INTENT1_TARGET}    ${INTENT1_IFACE_B}    ${SECRET_VALUE_1B}
    Verify Interface Description On Device    ${INTENT2_TARGET}    ${INTENT2_IFACE_A}    ${SECRET_VALUE_2A}
    Verify Interface Description On Device    ${INTENT2_TARGET}    ${INTENT2_IFACE_B}    ${SECRET_VALUE_2B}

TC3: Blame Redacts All Sensitive Leaves
    [Documentation]    kubectl sdc blame masks all four sensitive descriptions as *** on the target;
    ...    no plaintext secret value is leaked.
    [Tags]    redaction
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc blame --target ${INTENT1_TARGET} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${SENSITIVE_REDACTED}
    Should Not Contain    ${output}    ${SECRET_VALUE_1A}
    Should Not Contain    ${output}    ${SECRET_VALUE_1B}
    Should Not Contain    ${output}    ${SECRET_VALUE_2A}
    Should Not Contain    ${output}    ${SECRET_VALUE_2B}

TC4: Deviation On Sensitive Leaf Is Masked For Both Intents
    [Documentation]    Inject a deviation on the first interface of each intent; verify the Deviation CR
    ...    masks the sensitive value as *** in both cases and does not leak the plaintext.
    [Tags]    redaction
    Verify Deviation Masked
    ...    ${INTENT1_NAME}    ${INTENT1_TARGET}    ${INTENT1_IFACE_A}    ${SECRET_VALUE_1A}    deviation-override-1
    Verify Deviation Masked
    ...    ${INTENT2_NAME}    ${INTENT2_TARGET}    ${INTENT2_IFACE_A}    ${SECRET_VALUE_2A}    deviation-override-2

TC5: Missing Secret Sets ConfigResolverFailed, Last-Good SC Preserved
    [Documentation]    Delete intent 1's first secret (sensitive-1a); verify Config condition
    ...    ConfigResolverFailed=True and SensitiveConfig last-good payload is retained;
    ...    restoring the secret recovers the Config to Ready.
    [Tags]    negative
    ${sc_payload_before} =    Get Sensitive Config Payload    ${INTENT1_NAME}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete secret ${INTENT1_SECRET_A} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl annotate config.config.sdcio.dev/${INTENT1_NAME} -n ${SDCIO_RESOURCE_NAMESPACE} force-reconcile=$(date +%s) --overwrite
    Log    ${output}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Condition    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT1_NAME}    Resolver    False
    ${sc_payload_after} =    Get Sensitive Config Payload    ${INTENT1_NAME}
    Should Be Equal    ${sc_payload_before}    ${sc_payload_after}
    kubectl apply    ${CURDIR}/secrets/sensitive-1a.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT1_NAME}

TC6: Recovery Via TargetSnapshot After Pod Restart
    [Documentation]    After config-server pod restart, all four interface descriptions are restored
    ...    from TargetSnapshot for both intents.
    [Tags]    recovery
    ${desc1a_before} =    Get Interface Description On Device    ${INTENT1_TARGET}    ${INTENT1_IFACE_A}
    ${desc1b_before} =    Get Interface Description On Device    ${INTENT1_TARGET}    ${INTENT1_IFACE_B}
    ${desc2a_before} =    Get Interface Description On Device    ${INTENT2_TARGET}    ${INTENT2_IFACE_A}
    ${desc2b_before} =    Get Interface Description On Device    ${INTENT2_TARGET}    ${INTENT2_IFACE_B}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete pod -n ${SDCIO_SYSTEM_NAMESPACE} -l app.kubernetes.io/name=config-server --wait=false
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Wait Until Keyword Succeeds    5min    5s
    ...    Config-Server until config-Server deployment ready
    FOR    ${name}    IN    ${INTENT1_NAME}    ${INTENT2_NAME}
        Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${name}
    END
    ${desc1a_after} =    Get Interface Description On Device    ${INTENT1_TARGET}    ${INTENT1_IFACE_A}
    ${desc1b_after} =    Get Interface Description On Device    ${INTENT1_TARGET}    ${INTENT1_IFACE_B}
    ${desc2a_after} =    Get Interface Description On Device    ${INTENT2_TARGET}    ${INTENT2_IFACE_A}
    ${desc2b_after} =    Get Interface Description On Device    ${INTENT2_TARGET}    ${INTENT2_IFACE_B}
    Should Be Equal    ${desc1a_before}    ${desc1a_after}
    Should Be Equal    ${desc1b_before}    ${desc1b_after}
    Should Be Equal    ${desc2a_before}    ${desc2a_after}
    Should Be Equal    ${desc2b_before}    ${desc2b_after}

TC7: Admin Bypass Via include_sensitive [TODO — Deferred]
    [Documentation]    include_sensitive admin bypass requires --include-sensitive flag in kubectl-sdc (not yet implemented).
    [Tags]    TODO
    Skip    include_sensitive admin bypass requires --include-sensitive flag in kubectl-sdc (not yet implemented). Track at https://github.com/sdcio/kubectl-sdc

*** Keywords ***
Setup
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT1_TARGET}
    kubectl apply    ${CURDIR}/secrets/sensitive-1a.yaml
    kubectl apply    ${CURDIR}/secrets/sensitive-1b.yaml
    kubectl apply    ${CURDIR}/secrets/sensitive-2a.yaml
    kubectl apply    ${CURDIR}/secrets/sensitive-2b.yaml
    kubectl apply    ${CURDIR}/input/intent-sensitive-srl-1.yaml
    kubectl apply    ${CURDIR}/input/intent-sensitive-srl-2.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT1_NAME}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${INTENT2_NAME}

Cleanup
    FOR    ${name}    IN    ${INTENT1_NAME}    ${INTENT2_NAME}
        Run Keyword And Ignore Error
        ...    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${name}
        Run Keyword And Ignore Error
        ...    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${name}
    END
    FOR    ${secret}    IN    ${INTENT1_SECRET_A}    ${INTENT1_SECRET_B}    ${INTENT2_SECRET_A}    ${INTENT2_SECRET_B}
        Run Keyword And Ignore Error
        ...    Run And Return Rc And Output    kubectl delete secret ${secret} -n ${SDCIO_RESOURCE_NAMESPACE} --ignore-not-found
    END
    Run Keyword And Ignore Error
    ...    Run Keyword If Any Tests Failed    Delete Config from node
    ...    ${INTENT1_TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${INTENT1_IFACE_A}]"
    Run Keyword And Ignore Error
    ...    Run Keyword If Any Tests Failed    Delete Config from node
    ...    ${INTENT1_TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${INTENT1_IFACE_B}]"
    Run Keyword And Ignore Error
    ...    Run Keyword If Any Tests Failed    Delete Config from node
    ...    ${INTENT2_TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${INTENT2_IFACE_A}]"
    Run Keyword And Ignore Error
    ...    Run Keyword If Any Tests Failed    Delete Config from node
    ...    ${INTENT2_TARGET}    ${options}    ${SRL_USERNAME}    ${SRL_PASSWORD}
    ...    "/interface[name=${INTENT2_IFACE_B}]"

Verify Config Spec Retains Placeholders
    [Documentation]    The Config CR spec must still hold both ${vars.desc-a} and ${vars.desc-b}
    ...    template strings — not the resolved secret values.
    [Arguments]    ${name}    ${namespace}=${SDCIO_RESOURCE_NAMESPACE}
    ${output} =    kubectl get jsonpath
    ...    config.config.sdcio.dev    ${name}    ${namespace}    {.spec}
    Should Contain    ${output}    $\{vars.desc-a\}
    Should Contain    ${output}    $\{vars.desc-b\}

Verify Sensitive Config Payload Non Empty
    [Documentation]    SensitiveConfig must exist and carry a non-empty encrypted payload.
    [Arguments]    ${name}
    ${payload} =    Get Sensitive Config Payload    ${name}
    Should Not Be Empty    ${payload}

Get Sensitive Config Payload
    [Documentation]    Returns the raw base64 payload from the SensitiveConfig CR.
    [Arguments]    ${name}    ${namespace}=${SDCIO_RESOURCE_NAMESPACE}
    ${output} =    kubectl get jsonpath
    ...    sensitiveconfig.config.sdcio.dev    ${name}    ${namespace}    {.spec.payload.data}
    RETURN    ${output}

Verify Target Snapshot Contains Intent
    [Documentation]    TargetSnapshot for srl1 must list the given intent among its configs.
    [Arguments]    ${name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get targetsnapshot.config.sdcio.dev/${INTENT1_TARGET} -n ${SDCIO_RESOURCE_NAMESPACE} -o json | jq '.spec.configs | has("${name}")'
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${trimmed} =    Evaluate    """${output}""".strip()
    Should Be Equal As Strings    ${trimmed}    true

Config Check Condition
    [Documentation]    Assert that a specific condition type on a Config CR has the expected status value.
    [Arguments]    ${namespace}    ${name}    ${condition_type}    ${expected_status}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get config.config.sdcio.dev/${name} -n ${namespace} -o json
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${json} =    Convert string to JSON    ${output}
    ${status} =    Get values from JSON    ${json}    $.status.conditions[?(@.type=='${condition_type}')].status
    Should Be Equal As Strings    ${status}    ['${expected_status}']

Verify Interface Description On Device
    [Documentation]    Assert that the interface description on the device matches the expected value.
    [Arguments]    ${target}    ${iface}    ${expected_value}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${target}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path "/interface[name=${iface}]/description"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${expected_value}

Get Interface Description On Device
    [Documentation]    Retrieve the description leaf value of an interface from the device via gnmic.
    [Arguments]    ${target}    ${iface}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${target}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path "/interface[name=${iface}]/description" | jq -r '.[0].updates[0].values["interface/description"]'
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${output}

Inject Interface Description Deviation
    [Documentation]    Use gnmic to set a different description on a target interface, creating a deviation.
    [Arguments]    ${target}    ${iface}    ${value}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${target}} -p 57400 ${optionsSet} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} set --update-path "/interface[name=${iface}]/description" --update-value "${value}"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify Deviation Masked
    [Documentation]    Inject a deviation on an interface; verify the Deviation CR masks the sensitive
    ...    value as *** and does not expose the plaintext secret.
    [Arguments]    ${config_name}    ${target}    ${iface}    ${secret_value}    ${deviation_value}
    Inject Interface Description Deviation    ${target}    ${iface}    ${deviation_value}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Verify Deviation on k8s    ${config_name}    1
    ${deviation_name} =    Get Config Deviation Resource Name    ${config_name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${deviation_name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${SENSITIVE_REDACTED}
    Should Not Contain    ${output}    ${secret_value}
