*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Library             RPA.JSON
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/gnmic.robot
Resource            ../Keywords/yq.robot
Resource            ../Keywords/deviation.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup

*** Variables ***
# sr1 = netconf ; sr2 = gNMI get

@{SDCIO_SROS_NODES}     sr1    sr2
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4
&{intents}        intent1=vprn123    intent2=vprn234    intent3=vprn789    intent4=vprn987
${options}    --insecure -e JSON
${filter}    "configure/service/vprn"

*** Test Cases ***
Create Deviations and Verify non-revertive behavior
    [Documentation]    Create device deviations and Verify Non-Revertive Deviations on Config(Sets)
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        Log    Creating Deviations for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Creating Deviations on ${node} for intent ${intent}
            # Create a deviation for the intent by applying config directly on the device
            # Adjust the config on the device using gNMIc
            Set Config on node via file
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]/"
            ...    ${CURDIR}/input/sros/deviations-${intent}.json
        END
        # Wait until the deviation is reflected on k8s
        Log    Verifying Deviations are reflected on k8s for intent ${intent}
        # The deviation has been created, now verify the system will not rollback the deviation.
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            # Confirm in k8s that the config-server picks up the correct count of # deviations.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros-${node}
                ...    3
            ELSE
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros
                ...    3
            END
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros-nonrevertive.json
            # Wait until the deviation is applied on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            ...    ${expectedoutput}
            ...    ${filter}
        END
    END
    Sleep    10s

Reject Deviations and Verify revertive behavior
    [Documentation]    Reject Deviations and Verify Revertive Deviations on Config(Sets)
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        Log    Rejecting Deviations for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                Run Keyword
                ...    Delete Deviation CR
                ...    ${intent}-sros-${node}
            ELSE
                Run Keyword
                ...    Delete Deviation CR
                ...    ${intent}-sros
            END
        END
        # Wait some time to allow the system to process the rejection
        Sleep    5s
        # The deviation has been rejected, now verify the system will rollback the deviation.
        # Wait until the deviation is reflected on k8s
        Log    Verifying Deviations are reflected on k8s for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            # Confirm in k8s that the config-server clears the deviations.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros-${node}
                ...    0
            ELSE
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros
                ...    0
            END
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
            # Wait until the deviation is applied on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            ...    ${expectedoutput}
            ...    ${filter}
        END
    END
    Sleep    10s

Create Deviations, Partially accept and Verify, Fully accept and Verify
    [Documentation]    Create Deviations and Partially accept them on Config(Sets), then fully accept them and Verify
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        # CREATE
        Log    Creating Deviations for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Creating Deviations on ${node} for intent ${intent}
            # Create a deviation for the intent by applying config directly on the device
            # Adjust the config on the device using gNMIc
            Set Config on node via file
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]/"
            ...    ${CURDIR}/input/sros/deviations-${intent}.json
        END
        # Wait until the deviation is reflected on k8s
        Log    Verifying Deviations are reflected on k8s for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros-${node}
                ...    3
            ELSE
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros
                ...    3
            END
        END
        # PARTIALLY ACCEPT
        # Deviations are created, now partially accept them for the intent.
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros-nonrevertive-partial.yaml
        # Wait until the deviation is reflected on k8s
        Log    Verifying Deviations are reflected on k8s for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros-${node}
                ...    2
            ELSE
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros
                ...    2
            END
            # check if config matches here
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros-nonrevertive.json
            # Wait until the deviation is applied on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            ...    ${expectedoutput}
            ...    ${filter}
        END
        # FULLY ACCEPT
        # Deviations are created, now partially accept them for the intent.
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros-nonrevertive-full.yaml
        Log    Verifying Deviations are reflected on k8s for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros-${node}
                ...    0
            ELSE
                Wait Until Keyword Succeeds
                ...    2min
                ...    10s
                ...    Verify Deviation on k8s
                ...    ${intent}-sros
                ...    0
            END
            # check if config matches here
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros-nonrevertive.json
            # Wait until the deviation is applied on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            ...    ${expectedoutput}
            ...    ${filter}
        END
    END

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        kubectl patch    configset    ${intent}-sros    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        kubectl patch    config    ${intent}-sros    '{"spec": {"revertive": false}}'
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END

Cleanup
    Run    echo 'cleanup executed'
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-sros
    END
    Run Keyword If Any Tests Failed     DeleteAll
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "customer"

DeleteAll
    Log    Deleting all SROS Config
    FOR  ${node}    IN    @{SDCIO_SROS_NODES}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=*]"
    END
