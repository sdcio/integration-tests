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
&{replaceintents}        intent1=vrf11    intent2=vrf12    intent3=vrf13    intent4=vrf14    intent5=vrf15
&{intentsinterfaces}        intent1=ethernet-1/1    intent2=ethernet-1/2    intent3=ethernet-1/3    intent4=ethernet-1/4    intent5=ethernet-1/5
${options}    --skip-verify -e PROTO

*** Test Cases ***
Update and Verify ConfigSet
    [Documentation]    Verify ConfigSet resources are updated and verify on SRL nodes
    
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        # Update the ConfigSet Intent
        Log    Update ConfigSet for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl-update.yaml

        # Verify the ConfigSet is in a ready state in k8s
        Log    Verify Updated ConfigSet ${intent} is ready on k8s
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl

        # Verify the (updated) Config is applied on the SRL nodes
        Log   Verify Updated ConfigSet ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
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
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/srl/${intent}-srl-update.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl-update.json

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

Update and Verify Config
    [Documentation]    Verify Config resources are updated and verify on SRL nodes

    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        # Update the Config Intent
        Log    Update Config for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl-update.yaml

        # Verify the Config is in a ready state in k8s
        Log    Verify Updated Config ${intent} is ready on k8s
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl

        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is applied on the SRL nodes
        Log   Verify Updated Config ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
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
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/srl/${intent}-srl-update.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl-update.json

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

Replace and Verify ConfigSet
    [Documentation]    Verify ConfigSet resources are replaced and verify on SRL nodes
    
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        # Replace the ConfigSet Intent
        Log    Replace ConfigSet for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl-replace.yaml

        # Verify the ConfigSet is transitioning to a ready state in k8s
        Log    Verify Replaced ConfigSet ${intent} is ready on k8s
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl

        # Verify the (replaced) Config is applied on the SRL nodes
        Log   Verify Replaced ConfigSet ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
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
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/srl/${intent}-srl-replace.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl-replace.json

            ${compare} =    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${replaceintents.${intent}}]"
            ...    ${expectedoutput}
            
            Should Be True      ${compare}
        END
        Log  Verify Old ConfigSet ${intent} is removed from ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            ${output} =    Get Config from node
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"

    	    Should Be Empty    ${output}
        END
    END

Replace and Verify Config
    [Documentation]    Verify Config resources are replaced and verify on SRL nodes

    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        # Replace the Config Intent
        Log    Replace Config for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl-replace.yaml

        # Verify the Config is in a ready state in k8s
        Log    Verify Replaced Config ${intent} is ready on k8s
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl

        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is applied on the SRL nodes
        Log   Verify Replaced Config ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
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
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/srl/${intent}-srl-replace.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl-replace.json

            ${compare} =    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${replaceintents.${intent}}]"
            ...    ${expectedoutput}
            
            Should Be True      ${compare}
        END
        Log  Verify Old Config ${intent} is removed from ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
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
