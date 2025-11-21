*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Library             RPA.JSON
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/yq.robot
Resource            ../Keywords/gnmic.robot

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
Create and Verify Config(Set)
    [Documentation]    Verify Config(Set) resources are created and verify on SRL nodes
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        # Apply the Config(Set) Intent
        Log    Create Config(Set) for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml

        # Verify the ConfigSet is transitioning to a ready state in k8s
        IF    $intent in $SDCIO_CONFIGSET_INTENTS
            Log    Verify ConfigSet ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    ConfigSet Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-srl
        ELSE
            Log    Verify Config ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Config Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-srl
        END

        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is applied on the SRL nodes
        Log   Verify Config(Set) ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == '${EMPTY}'
                ${targetdevice} =    ${node}
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            # Note, as the gnmic output is not properly JSON formatted, we need to save the gnmic output initially to a file, 
            # to be able to compare it in consecutive runs.
            # ONLY UNCOMMENT THE FOLLOWING LINE IF YOU NEED TO UPDATE THE EXPECTED OUTPUT
            # START BLOCK
            # ${gnmicoutput} =    Get Config from node
            # ...    ${node}
            # ...    ${options}
            # ...    ${SRL_USERNAME}
            # ...    ${SRL_PASSWORD}
            # ...    "/network-instance[name=${intents.${intent}}]"
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

            ${compare} =    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            ...    ${expectedoutput}
            
            Should Be True      ${compare}
        END
    END

Delete and Verify Config(Set)
    [Documentation]    Delete Config(Set) resources are deleted in k8s and on SRL nodes
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        IF    $intent in $SDCIO_CONFIGSET_INTENTS
            # Delete the ConfigSet Intent
            Log    Delete ConfigSet for intent ${intent}
            ${rc}    ${output}=    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
            
            # Verify the ConfigSet is gone in k8s
            Log    Verify ConfigSet ${intent} is gone on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Run Keyword And Expect Error    *
            ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-srl
        ELSE
            # Delete the Config Intent
            Log    Delete Config for intent ${intent}
            ${rc}    ${output} =    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-srl
    
            # Verify the Config is gone in k8s
            Log    Verify Config ${intent} is gone on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Run Keyword And Expect Error    *
            ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-srl
        END

        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
        # Verify the Config is gone on the SRL nodes
        Log   Verify Config ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # If the targetdevice is not defined in the intent yaml, assume all nodes.
            IF    '${targetdevice}' == '${EMPTY}'
                ${targetdevice} =    ${node}
            END
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            ${output} =    Get Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"

    	    Should Be Empty    ${output}
        END
    END

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END

Cleanup
    Run    echo 'cleanup executed'
    Run Keyword If Any Tests Failed     DeleteAll

DeleteAll
    Log    Deleting all SRL Config
    FOR  ${node}    IN    @{SDCIO_SRL_NODES}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    "/network-instance[name=vrf*]"
        @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

        FOR   ${intent}    IN    @{SDCIO_ALL_INTENTS}
            Delete Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intentsinterfaces.${intent}}]"
        END
    END
