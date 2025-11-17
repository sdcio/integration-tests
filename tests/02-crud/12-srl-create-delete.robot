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

*** Test Cases ***
Create and Verify ConfigSet
    [Documentation]    Verify ConfigSet resources are created and verify on SRL nodes
    
    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
        # Apply the ConfigSet Intent
        Log    Create ConfigSet for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml

        # Verify the ConfigSet is transitioning to a ready state in k8s
        Log    Verify ConfigSet ${intent} is ready on k8s
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    ConfigSet Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl

        # Verify the Config is applied on the SRL nodes
        Log   Verify ConfigSet ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            ${rc}    ${output}=    Get Config from node
            ...    ${node}
            ...    --skip-verify -e PROTO
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            
            ${gnmicoutput} =    Get value from JSON    ${output}    $.[*].values

            # Note, as the gnmic output is not properly JSON formatted, we need to save the gnmic output initially to a file, 
            # to be able to compare it in consecutive runs.
            # ONLY UNCOMMENT THE FOLLOWING LINE IF YOU NEED TO UPDATE THE EXPECTED OUTPUT
            Save JSON to file    ${output}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

            # Load the previously saved expected output, and compare it with the actual gnmic output            
            &{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

            Dictionaries Should Be Equal    ${gnmicoutput}    ${expectedoutput}
        END
    END

Create and Verify Config
    [Documentation]    Verify Config resources are created and verify on SRL nodes

    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
        # Apply the Config Intent
        Log    Create Config for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/srl/${intent}-srl.yaml

        # Verify the Config is transitioning to a ready state in k8s
        Log    Verify Config ${intent} is ready on k8s
        Wait Until Keyword Succeeds
        ...    2min
        ...    10s
        ...    Config Check Ready
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${intent}-srl

        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is applied on the SRL nodes
        Log   Verify Config ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            ${rc}    ${output}=    Get Config from node
            ...    ${node}
            ...    --skip-verify -e PROTO
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            ${gnmicoutput} =    Get value from JSON    ${output}    $.[*].values

            # Note, as the gnmic output is not properly JSON formatted, we need to save the gnmic output initially to a file, 
            # to be able to compare it in consecutive runs.
            # ONLY UNCOMMENT THE FOLLOWING LINE IF YOU NEED TO UPDATE THE EXPECTED OUTPUT
            Save JSON to file    ${output}    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

            # Load the previously saved expected output, and compare it with the actual gnmic output            
            &{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/srl/${intent}-srl.json

            Dictionaries Should Be Equal    ${gnmicoutput}    ${expectedoutput}
        END
    END


Delete and Verify Config
    [Documentation]    Delete Config resources are deleted in k8s and on SRL nodes

    FOR    ${intent}    IN    @{SDCIO_CONFIG_INTENTS}
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


        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/srl/${intent}-srl.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
        # Verify the Config is gone on the SRL nodes
        Log   Verify Config ${intent} on ${SDCIO_SRL_NODES}
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            # considering we're looping through all SRL nodes, skip checking for config on nodes that are not defined in the input yaml.
            IF    '${node}' != '${targetdevice}'
                Log   Skipping node ${node} as it is not the target device ${targetdevice}
                Continue For Loop
            END
            ${rc}    ${output}=    Get Config from node
            ...    ${node}
            ...    --skip-verify -e PROTO
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            ${gnmicoutput} =    Get value from JSON    ${output}    $.[*].values

            Should Be Equal    ${gnmicoutput}    ${None}
        END
    END

Delete and Verify ConfigSet
    [Documentation]    Delete ConfigSet resources are deleted in k8s and on SRL nodes

    FOR    ${intent}    IN    @{SDCIO_CONFIGSET_INTENTS}
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

        # Verify the Config is gone on the SRL nodes
        Log   Verify ConfigSet ${intent} on ${SDCIO_SRL_NODES}
        # Verify the Config is gone on the SRL nodes
        FOR    ${node}    IN    @{SDCIO_SRL_NODES}
            ${rc}    ${output}=    Get Config from node
            ...    ${node}
            ...    --skip-verify -e PROTO
            ...    ${SRL_USERNAME}
            ...    ${SRL_PASSWORD}
            ...    "/network-instance[name=${intents.${intent}}]"
            ${gnmicoutput} =    Get value from JSON    ${output}    $.[*].values

            Should Be Equal    ${gnmicoutput}    ${None}
        END
    END

*** Keywords ***
Setup
    Run    echo 'setup executed'
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    srl1
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    srl2
    Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    srl3

Cleanup
    Run    echo 'cleanup executed'
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
    END