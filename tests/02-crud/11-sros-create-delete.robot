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

@{SDCIO_SROS_NODES}     sr1    sr2
@{SDCIO_CONFIGSET_INTENTS}    intent1    intent2
@{SDCIO_CONFIG_INTENTS}    intent3    intent4
&{intents}        intent1=vprn123    intent2=vprn234    intent3=vprn789    intent4=vprn987
${options}    --insecure -e JSON
${filter}    "configure/service/vprn"

*** Test Cases ***
Create and Verify Config(Set)
    [Documentation]    Verify Config(Set) resources are created and verify on SROS nodes
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        # Apply the Config(Set) Intent
        Log    Create Config(Set) for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/sros/${intent}-sros.yaml
        
        # Verify the Config(Set) is transitioning to a ready state in k8s
        IF    $intent in $SDCIO_CONFIGSET_INTENTS
            Log    Verify ConfigSet ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    ConfigSet Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-sros
        ELSE
            Log    Verify Config ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Config Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-sros
        END

        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is applied on the SROS nodes
        Log   Verify Config(Set) ${intent} on ${SDCIO_SROS_NODES}
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
            # Clearing targetdevice variable for next iteration
            ${targetdevice} =    Set Variable    'null'
            # Note, as the gnmic output is not properly JSON formatted, we need to save the gnmic output initially to a file, 
            # to be able to compare it in consecutive runs.
            # ONLY UNCOMMENT THE FOLLOWING LINES IF YOU NEED TO UPDATE THE EXPECTED OUTPUT
            # START BLOCK
            # ${gnmicoutput} =    Get Config from node
            # ...    ${node}
            # ...    ${options}
            # ...    ${SROS_USERNAME}
            # ...    ${SROS_PASSWORD}
            # ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            # ...    ${filter}
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/sros/${intent}-sros.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros.json

            ${compare} =    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${intents.${intent}}]"
            ...    ${expectedoutput}
            ...    ${filter}
            
            Should Be True      ${compare}
        END
    END

Delete and Verify Config(Set)
    [Documentation]    Delete Config(Set) resources are deleted in k8s and on SROS nodes
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        IF    $intent in $SDCIO_CONFIGSET_INTENTS
            # Delete the ConfigSet Intent
            Log    Delete ConfigSet for intent ${intent}
            ${rc}    ${output}=    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
    
            # Verify the ConfigSet is gone in k8s
            Log    Verify ConfigSet ${intent} is gone on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Run Keyword And Expect Error    *
            ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev ${intent}-sros
        ELSE
            # Delete the Config Intent
            Log    Delete Config for intent ${intent}
            ${rc}    ${output} =    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    ${intent}-sros
            
            # Verify the Config is gone in k8s
            Log    Verify Config ${intent} is gone on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Run Keyword And Expect Error    *
            ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev ${intent}-sros
        END
        
        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'
        # Verify the Config is gone on the SROS nodes
        Log   Verify Config ${intent} on ${SDCIO_SROS_NODES}
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
            # Clearing targetdevice variable for next iteration
            ${targetdevice} =    Set Variable    'null'
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
    END

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Wait Until Keyword Succeeds    15min    10s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    ${node}
    END
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"

Cleanup
    Run    echo 'cleanup executed'
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
