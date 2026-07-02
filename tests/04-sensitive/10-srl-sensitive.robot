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
${SENSITIVE_CONFIG_NAME}    intent-sensitive-srl
${SENSITIVE_TARGET}         srl1
${SENSITIVE_IFACE}          ethernet-1/6
${SENSITIVE_SECRET_VALUE}   my-sensitive-description
${SENSITIVE_REDACTED}       ***
${options}                  --skip-verify -e PROTO
${optionsSet}               --skip-verify -e JSON_IETF
${eventual_timeout}         2min
${retry}                    2s

*** Test Cases ***
TC1: Apply Sensitive Config And Verify K8s Pipeline
    [Documentation]    Verify Config CR is Ready, spec retains placeholder, SensitiveConfig has payload, and TargetSnapshot records the intent.
    [Tags]    happy-path
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_CONFIG_NAME}
    Verify Config Spec Retains Placeholder
    Verify Sensitive Config Payload Non Empty
    Verify Target Snapshot Contains Intent

TC2: Verify Device Has Resolved Value
    [Documentation]    Device has the actual plaintext secret value applied southbound (not redacted).
    [Tags]    happy-path
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${SENSITIVE_TARGET}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path "/interface[name=${SENSITIVE_IFACE}]/description"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${SENSITIVE_SECRET_VALUE}

TC3: Blame Redacts Sensitive Leaf
    [Documentation]    kubectl sdc blame masks the sensitive value as *** and does not leak the plaintext.
    [Tags]    redaction
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl sdc blame --target ${SENSITIVE_TARGET} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${SENSITIVE_REDACTED}
    Should Not Contain    ${output}    ${SENSITIVE_SECRET_VALUE}

TC4: Deviation On Sensitive Leaf Is Masked
    [Documentation]    Inject a deviation on ethernet-1/6 description; verify the Deviation CR masks the value.
    [Tags]    redaction
    Inject Interface Description Deviation    deviation-override
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Verify Deviation on k8s    ${SENSITIVE_CONFIG_NAME}    1
    ${deviation_name} =    Get Config Deviation Resource Name    ${SENSITIVE_CONFIG_NAME}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${deviation_name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Contain    ${output}    ${SENSITIVE_REDACTED}
    Should Not Contain    ${output}    ${SENSITIVE_SECRET_VALUE}

TC5: Missing Secret Sets ConfigResolverFailed, Last-Good SC Preserved
    [Documentation]    Delete the payload secret; verify Config condition ConfigResolverFailed=True and SensitiveConfig last-good payload is retained.
    [Tags]    negative
    ${sc_payload_before} =    Get Sensitive Config Payload
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete secret sensitive-payload -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl annotate config.config.sdcio.dev/${SENSITIVE_CONFIG_NAME} -n ${SDCIO_RESOURCE_NAMESPACE} force-reconcile=$(date +%s) --overwrite
    Log    ${output}
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Condition    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_CONFIG_NAME}    Resolver    False
    ${sc_payload_after} =    Get Sensitive Config Payload
    Should Be Equal    ${sc_payload_before}    ${sc_payload_after}
    kubectl apply    ${CURDIR}/secrets/secret-sensitive-payload.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_CONFIG_NAME}

TC6: Recovery Via TargetSnapshot After Pod Restart
    [Documentation]    After config-server pod restart, device description is restored from TargetSnapshot.
    [Tags]    recovery
    ${desc_before} =    Get Interface Description On Device
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete pod -n ${SDCIO_SYSTEM_NAMESPACE} -l app.kubernetes.io/name=config-server --wait=false
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    Wait Until Keyword Succeeds    5min    5s
    ...    Config-Server until config-Server deployment ready
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_CONFIG_NAME}
    ${desc_after} =    Get Interface Description On Device
    Should Be Equal    ${desc_before}    ${desc_after}

TC7: Admin Bypass Via include_sensitive [TODO — Deferred]
    [Documentation]    include_sensitive admin bypass requires --include-sensitive flag in kubectl-sdc (not yet implemented).
    [Tags]    TODO
    Skip    include_sensitive admin bypass requires --include-sensitive flag in kubectl-sdc (not yet implemented). Track at https://github.com/sdcio/kubectl-sdc

*** Keywords ***
Setup
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_TARGET}
    kubectl apply    ${CURDIR}/secrets/secret-sensitive-payload.yaml
    kubectl apply    ${CURDIR}/input/intent-sensitive-srl.yaml
    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_CONFIG_NAME}

Cleanup
    Run Keyword And Ignore Error
    ...    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${SENSITIVE_CONFIG_NAME}
    Run Keyword And Ignore Error
    ...    Wait Until Keyword Succeeds    ${eventual_timeout}    ${retry}
    ...    Run Keyword And Expect Error    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${SENSITIVE_CONFIG_NAME}
    Run Keyword And Ignore Error
    ...    Run And Return Rc And Output    kubectl delete secret sensitive-payload -n ${SDCIO_RESOURCE_NAMESPACE} --ignore-not-found
    Run Keyword If Any Tests Failed
    ...    Delete Config from node
    ...    ${SENSITIVE_TARGET}
    ...    ${options}
    ...    ${SRL_USERNAME}
    ...    ${SRL_PASSWORD}
    ...    "/interface[name=${SENSITIVE_IFACE}]"

Verify Config Spec Retains Placeholder
    [Documentation]    The Config CR spec must still hold the $\{vars.desc\} template string, not the resolved value.
    [Arguments]    ${name}=${SENSITIVE_CONFIG_NAME}    ${namespace}=${SDCIO_RESOURCE_NAMESPACE}
    ${output} =    kubectl get jsonpath
    ...    config.config.sdcio.dev    ${name}    ${namespace}    {.spec}
    Should Contain    ${output}    $\{vars.desc\}

Verify Sensitive Config Payload Non Empty
    [Documentation]    SensitiveConfig must exist and carry a non-empty encrypted payload.
    ${payload} =    Get Sensitive Config Payload
    Should Not Be Empty    ${payload}

Get Sensitive Config Payload
    [Documentation]    Returns the raw base64 payload from the SensitiveConfig CR.
    [Arguments]    ${name}=${SENSITIVE_CONFIG_NAME}    ${namespace}=${SDCIO_RESOURCE_NAMESPACE}
    ${output} =    kubectl get jsonpath
    ...    sensitiveconfig.config.sdcio.dev    ${name}    ${namespace}    {.spec.payload.data}
    RETURN    ${output}

Verify Target Snapshot Contains Intent
    [Documentation]    TargetSnapshot for srl1 must list intent-sensitive-srl among its configs.
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get targetsnapshot.config.sdcio.dev/${SENSITIVE_TARGET} -n ${SDCIO_RESOURCE_NAMESPACE} -o json | jq '.spec.configs | has("${SENSITIVE_CONFIG_NAME}")'
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

Inject Interface Description Deviation
    [Documentation]    Use gnmic to set a different description on the target interface, creating a deviation.
    [Arguments]    ${value}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${SENSITIVE_TARGET}} -p 57400 ${optionsSet} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} set --update-path "/interface[name=${SENSITIVE_IFACE}]/description" --update-value "${value}"
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Get Interface Description On Device
    [Documentation]    Retrieve the description leaf value of SENSITIVE_IFACE from the device via gnmic.
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${SENSITIVE_TARGET}} -p 57400 ${options} -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path "/interface[name=${SENSITIVE_IFACE}]/description" | jq -r '.[0].updates[0].values["interface/description"]'
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${output}
