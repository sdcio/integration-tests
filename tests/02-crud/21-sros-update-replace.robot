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
&{replaceintents}        intent1=vprn1123    intent2=vprn1234    intent3=vprn1789    intent4=vprn1987
${options}    --insecure -e JSON
${filter}    "configure/service/vprn"

*** Test Cases ***
Update and Verify Config(Set)
    [Documentation]    Verify Config(Set) resources are updated and verify on SROS nodes
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        # Update the Config(Set) Intent
        Log    Update Config(Set) for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/sros/${intent}-sros-update.yaml

        IF    $intent in $SDCIO_CONFIGSET_INTENTS
            # Verify the (updated) ConfigSet is in a ready state in k8s
            Log    Verify Updated ConfigSet ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    ConfigSet Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-sros
        ELSE    
            # Verify the (updated) Config is transitioning to a ready state in k8s
            Log    Verify Updated Config ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Config Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-sros
        END
        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is replaced on the SROS nodes
        Log   Verify Upgraded ConfigSet ${intent} on ${SDCIO_SROS_NODES}
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
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/sros/${intent}-sros-update.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros-update.json

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

Replace and Verify Config(Set)
    [Documentation]    Verify Config(Set) resources are replaced and verify on SROS nodes
    @{SDCIO_ALL_INTENTS} =    Combine Lists    ${SDCIO_CONFIGSET_INTENTS}    ${SDCIO_CONFIG_INTENTS}

    FOR    ${intent}    IN    @{SDCIO_ALL_INTENTS}
        # Replace the Config(Set) Intent
        Log    Replace Config(Set) for intent ${intent}
        ${rc}    ${output}=    kubectl apply    ${CURDIR}/input/sros/${intent}-sros-replace.yaml

        IF    $intent in $SDCIO_CONFIGSET_INTENTS
            # Verify the (replaced) ConfigSet is in a ready state in k8s
            Log    Verify Replaced ConfigSet ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    ConfigSet Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-sros
        ELSE
            # Verify the (replaced) Config is transitioning to a ready state in k8s
            Log    Verify Replaced Config ${intent} is ready on k8s
            Wait Until Keyword Succeeds
            ...    2min
            ...    10s
            ...    Config Check Ready
            ...    ${SDCIO_RESOURCE_NAMESPACE}
            ...    ${intent}-sros
        END
        ${rc}    ${targetdevice} =   YQ file    ${CURDIR}/input/sros/${intent}-sros.yaml    '.metadata.labels."config.sdcio.dev/targetName"'

        # Verify the Config is replaced on the SROS nodes
        Log   Verify Replaced Config(Set) ${intent} on ${SDCIO_SROS_NODES}
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
            # Note, as the gnmic output is not properly JSON formatted, we need to save the gnmic output initially to a file, 
            # to be able to compare it in consecutive runs.
            # ONLY UNCOMMENT THE FOLLOWING LINES IF YOU NEED TO UPDATE THE EXPECTED OUTPUT
            # START BLOCK
            # ${gnmicoutput} =    Get Config from node
            # ...    ${node}
            # ...    ${options}
            # ...    ${SROS_USERNAME}
            # ...    ${SROS_PASSWORD}
            # ...    "/configure/service/vprn[service-name=${replaceintents.${intent}}]"
            # ...    ${filter}
            # Save JSON to file    ${gnmicoutput}    ${CURDIR}/expectedoutput/sros/${intent}-sros-replace.json
            # END BLOCK

            @{expectedoutput} =    Load JSON from file    ${CURDIR}/expectedoutput/sros/${intent}-sros-replace.json

            ${compare} =    Get Config from node and Verify Intent
            ...    ${node}
            ...    ${options}
            ...    ${SROS_USERNAME}
            ...    ${SROS_PASSWORD}
            ...    "/configure/service/vprn[service-name=${replaceintents.${intent}}]"
            ...    ${expectedoutput}
            ...    ${filter}

            Should Be True      ${compare}
        END
        
        # Verify the old Config is gone on the SROS nodes
        Log   Verify Old Config(Set) ${intent} is gone on ${SDCIO_SROS_NODES}
        FOR    ${node}    IN    @{SDCIO_SROS_NODES}
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
