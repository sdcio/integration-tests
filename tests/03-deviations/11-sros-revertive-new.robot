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

@{SDCIO_SROS_NODES}     sr1    sr2
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4
&{intents}        intent1=vprn123    intent2=vprn234    intent3=vprn789    intent4=vprn987
${options}    --insecure -e JSON
${filter}    "configure/service/vprn"

*** Test Cases ***
Delete SROS device ConfigSet and Verify Revertive Deviations
    [Documentation]    Delete device config and Verify Revertive Deviations on ConfigSets
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        Log    Delete device config for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == 'null'
                ${targetdevice} =    Set Variable    ${node}
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Delete ConfigSet ${intent} on ${node}
            # Delete the config from the device using gNMIc
            Delete Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            # Verify the config is deleted from the device using gNMIc
            Log    Verify Deletion of ConfigSet ${intent} on ${node}
            ${output} =    Get Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            ...    ${filter}

            # [HT] Fix, remove None values from output list, before checking if it's empty
            ${output} =   Evaluate    [i for i in ${output} if i]
    	    Should Be Empty    ${output}
        END
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == 'null'
                ${targetdevice} =    Set Variable    ${node}
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Wait for Deviations to pick up and revert the config delete on ${node}
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
            # Wait until the config is reverted back on the device using gNMIc
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

Delete ALL SROS device config and Verify Revertive Deviations
    [Documentation]    Delete device config and Verify Revertive Deviations on ConfigSets
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Log    Deleting ALL Config(Set) intents on ${node}
        # Delete the config from the device using gNMIc
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=*]"
        # Verify the config is deleted from the device using gNMIc
        Log    Verify Deletion of Config(Set) intents on ${node}
        ${output} =    Get Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SROS_USERNAME}
        ...    ${SROS_PASSWORD}
        ...    "/configure/service/vprn[service-name=*]"
        ...    ${filter}
        # [HT] Fix, remove None values from output list, before checking if it's empty
        ${output} =   Evaluate    [i for i in ${output} if i]
        Should Be Empty    ${output}
    END
    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == 'null'
                ${targetdevice} =    Set Variable    ${node}
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Wait for Deviations to pick up and revert the config delete on ${node}
            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
            # Wait until the config is reverted back on the device using gNMIc
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

Adjust SROS device config and Verify Revertive Deviations
    [Documentation]    Adjust SROS device config and Verify Revertive Deviations
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}
    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        Log    Adjust device config for intent ${intent}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == 'null'
                ${targetdevice} =    Set Variable    ${node}
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            Log    Creating Deviations on ${node} for intent ${intent}
            # Adjust the config on the device using gNMIc
            Set Config on node via file
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]/"
            ...    ${CURDIR}/input/sros/deviation-${intent}.json
            # Verify the config is adjusted on the device using gNMIc
            Log    Verify Deviation Creation on ${node} of intent ${intent}
        END
        # The deviation has been created, now verify the system will rollback the deviation and the original intent is back in place
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == 'null'
                ${targetdevice} =    Set Variable    ${node}
            END
            # considering we're looping through all SROS nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
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
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-sros
    END
    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
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
