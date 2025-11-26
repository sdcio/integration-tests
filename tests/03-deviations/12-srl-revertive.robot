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

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup

*** Variables ***
# sr1 = netconf ; sr2 = gNMI get

@{SDCIO_SRL_NODES}     srl1    srl2    srl3
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4    intent5
&{intents}        intent1=vrf1    intent2=vrf2    intent3=vrf3    intent4=vrf4    intent5=vrf5
&{intentsinterfaces}        intent1=ethernet-1/1    intent2=ethernet-1/2    intent3=ethernet-1/3    intent4=ethernet-1/4    intent5=ethernet-1/5
${options}    --skip-verify -e PROTO


*** Test Cases ***
Delete SRL device config and Verify Revertive Deviations
    [Documentation]    Delete device config and Verify Revertive Deviations on ConfigSets
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        Log    Delete device config for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Delete ConfigSet ${intent} on ${node}
            # Delete the config from the device using gNMIc
            Delete Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            # Verify the config is deleted from the device using gNMIc
            Log    Verify Deletion of ConfigSet ${intent} on ${node}
            ${output} =    Get Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"

    	    Should Be Empty    ${output}
        END
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Wait for Deviations to pick up and revert the config delete on ${node}
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
            # Wait until the config is reverted back on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}] --path /interface[name=${intentsinterfaces.${intent}}]"
            ...    ${expectedoutput}
        END
    END

Delete ALL SRL device config and Verify Revertive Deviations
    [Documentation]    Delete device config and Verify Revertive Deviations on Config(Set) -- multiple intents at once
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Log    Deleting ALL Config(Set) intents on ${node}
        # Delete the config from the device using gNMIc
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=vrf*]"
        # Verify the config is deleted from the device using gNMIc
        Log    Verify Deletion of Config(Set) intents on ${node}
        ${output} =    Get Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=vrf*]"

        Should Be Empty    ${output}
    END
    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Wait for Deviations to pick up and revert the config delete on ${node}
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
            # Wait until the config is reverted back on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}] --path /interface[name=${intentsinterfaces.${intent}}]"
            ...    ${expectedoutput}
        END
    END

Adjust SRL device config and Verify Revertive Deviations
    [Documentation]    Adjust (some) SRL device config and Verify Revertive Deviations
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}
    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        Log    Adjust device config for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Creating Deviations on ${node} for intent ${intent}
            # Adjust the config on the device using gNMIc
            Set Config on node via file
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            ...    ${CURDIR}/input/srl/deviations-${intent}.json
            # Verify the config is adjusted on the device using gNMIc
            Log    Verify Deviation Creation on ${node} of intent ${intent}
        END
        # The deviation has been created, now verify the system will rollback the deviation and the original intent is back in place
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the intent is a ConfigSet, we need to run on all nodes, else we get the targetdevice from the intent yaml.
            IF    $intent in $SDCIO_CONFIGSET_INTENTS
                ${targetdevice} =    Set Variable    ${node}
            ELSE
                ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
            # Wait until the deviation is applied on the device using gNMIc
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}] --path /interface[name=${intentsinterfaces.${intent}}]"
            ...    ${expectedoutput}
        END
    END

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl
    END

Cleanup
    Run    echo 'cleanup executed'
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-srl
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Run Keyword And Expect Error    *
        ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-srl
    END
    Run Keyword If Any Tests Failed     DeleteAll

DeleteAll
    Log    Deleting all SRL Config
    FOR  ${node}    IN    @{SDCIO_SRL_NODES}
        Delete Config from node
        ...    ${node}
        ...    --skip-verify -e PROTO
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=vrf*]"
        Delete Config from node
        ...    ${node}
        ...    --skip-verify -e PROTO
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/interface[name=ethernet-1/*]"
    END
