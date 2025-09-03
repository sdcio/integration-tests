*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/config.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
@{SDCIO_SROS_NODES}     sr1    sr2
${operation}            Deviation:nonrevertive
${intent1}              "service-name": "vprn123"
${intent2}              "service-name": "vprn234"
${intent3}              "service-name": "vprn789"
${intent4}              "service-name": "vprn987"
${adminstate}           "admin-state": "enable"
${customer}             "customer": "1"
${null}                 "configure/service/vprn": null


*** Test Cases ***

# Non-revertive ConfigSet intent1-sros is applied, change values on device, witness the deviation counter increase, verify the ConfigSet on the devices.

${operation} - Create Deviation: adjust config (intent1-sros) on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]/service-id"
    ...    "1101"
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]/customer"
    ...    '"2"'
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]/service-id"
    ...    "1101"
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]/customer"
    ...    '"2"'
Verify - ${operation} Deviation counter is 3 on intent1-sros-sr1 and intent1-sros-sr2 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-sros-sr1
    ...    3
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-sros-sr2
    ...    3
Verify - ${operation} Deviations (intent1-sros) are persistently applied on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 1101
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "customer": "2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 1101
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "customer": "2"

# Reject the intent (delete the deviation CR), verify the intent is back in it's original state.
Reject Deviation - ${operation} Delete the Deviation CR (intent1-sros) applied on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-sros-sr1
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-sros-sr2

Verify - ${operation} Rejected Deviations (intent1-sros) are now gone on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 101
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "customer": "1"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 101
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "customer": "1"

Verify - ${operation} Deviation counter == 0 for intent1-sros-sr1 and intent1-sros-sr2 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-sros-sr1
    ...    0
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-sros-sr2
    ...    0

${operation} - Create Deviation: adjust config (intent2-sros) on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]/service-id"
    ...    "1102"
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]/customer"
    ...    '"2"'
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]/service-id"
    ...    "1102"
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]/customer"
    ...    '"2"'
Verify - ${operation} Deviation counter is 3 on intent2-sros-sr1 and intent2-sros-sr2 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-sros-sr1
    ...    3
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-sros-sr2
    ...    3
Verify - ${operation} Deviations (intent2-sros) are persistently applied on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"

# Accept the deviation (patch the original intent CR), verify the deviation counter is reset to 0, verify the state on the device matches the patched intent.
Partially Accept Deviation - ${operation} Patch intent2-sros applied on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    kubectl patch
    ...    configset
    ...    intent2-sros
    ...    '{"spec": {"config": [{"path":"/","value":{"configure":{"service":{"vprn":{"admin-state":"enable","customer":"2","service-id":"102","service-name":"vprn234"}}}}}]}}'

Verify - ${operation} Deviation counter is 2 on intent2-sros-sr1 and intent2-sros-sr2 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-sros-sr1
    ...    2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-sros-sr2
    ...    2
    
Verify - ${operation} Deviations ConfigSet intent2-sros are partially accepted on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"

Fully Accept Deviation - ${operation} Patch intent2-sros applied on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    kubectl patch
    ...    configset
    ...    intent2-sros
    ...    '{"spec": {"config": [{"path":"/","value":{"configure":{"service":{"vprn":{"admin-state":"disable","customer":"2","service-id":"1102","service-name":"vprn234"}}}}}]}}'

Verify - ${operation} Deviation counter is 0 on intent2-sros-sr1 and intent2-sros-sr2 on k8s
    Wait Until Keyword Succeeds
    ...    4min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-sros-sr1
    ...    0
    Wait Until Keyword Succeeds
    ...    4min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-sros-sr2
    ...    0
    
Verify - ${operation} Deviations ConfigSet intent2-sros are fully accepted on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"

${operation} - Create Deviation: adjust config (intent3-sros) on sr1
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]/service-id"
    ...    "1103"
    Run Keyword
    ...    Set Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]/customer"
    ...    '"2"'

Verify - ${operation} Deviation counter is 3 on intent3-sros on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent3-sros
    ...    3

Verify - ${operation} Deviations (intent3-sros) are persistently applied on sr1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "service-id": 1103
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "customer": "2"
# Reject the intent (delete the deviation CR), verify the intent is back in it's original state.
Reject Deviation - ${operation} Delete the Deviation CR intent3-sros applied on sr1
    Run Keyword
    ...    Delete Deviation CR
    ...    intent3-sros

Verify - ${operation} Rejected Deviations (intent3-sros) is now gone on sr1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "service-id": 103
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "customer": "1"
Verify - ${operation} Deviation counter is reset intent3-sros on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent3-sros
    ...    0

${operation} - Create Deviation: adjust config (intent4-sros) on sr2
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]/service-id"
    ...    "1104"
    Run Keyword
    ...    Set Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]/customer"
    ...    '"2"'

Verify - ${operation} Deviation counter is 3 on intent4-sros on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent4-sros
    ...    3

Verify - ${operation} Deviations (intent4-sros) are persistently applied on sr2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "service-id": 1104
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "customer": "2"

# Accept the deviation (patch the original intent CR), verify the deviation counter is reset to 0, verify the state on the device matches the patched intent.

Partially Accept Deviation - ${operation} Patch intent4-sros applied on sr2
    Run Keyword
    ...    kubectl patch
    ...    config
    ...    intent4-sros
    ...    '{"spec": {"config": [{"path":"/","value":{"configure":{"service":{"vprn":{"admin-state":"enable","customer":"2","service-id":"104","service-name":"vprn987"}}}}}]}}'

Verify - ${operation} Deviation counter is 2 on intent4-sros on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent4-sros
    ...    2

Verify - ${operation} Deviations Config intent4-sros is partially accepted on sr2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "service-id": 1104
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "customer": "2"

Fully Accept Deviation - ${operation} Patch intent4-sros applied on sr2
    Run Keyword
    ...    kubectl patch
    ...    config
    ...    intent4-sros
    ...    '{"spec": {"config": [{"path":"/","value":{"configure":{"service":{"vprn":{"admin-state":"disable","customer":"2","service-id":"1104","service-name":"vprn987"}}}}}]}}'

Verify - ${operation} Deviation counter is 0 on intent4-sros on k8s
    Wait Until Keyword Succeeds
    ...    4min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent4-sros
    ...    0

Verify - ${operation} Deviations Config intent4-sros is fully accepted on sr2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "service-id": 1104
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "customer": "2"

*** Keywords ***

Verify Deviation on k8s
    [Documentation]    Verify the deviation CR on k8s, check if the deviation counter is increased
    [Arguments]    ${name}    ${match}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl get deviation.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE} -o json | jq '.spec.deviations // [] | length'
    Log    ${output}
    ${result} =	    Convert To Integer    ${output}
    Should Be Equal As Integers    ${rc}    0
    Should Be Equal As Integers    ${result}    ${match}

Verify ConfigSet intent on nodes
    [Documentation]    Iterates through the SDCIO_SROS_NODES, validates if the output contains $intent and $adminstate for gNMI $path
    [Arguments]    ${path}    ${intent}    ${adminstate}
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Verify Config on node    ${node}    ${path}    ${intent}    ${adminstate}
    END

Verify Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}    ${match}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path ${path}
    Log    ${output}
    Should Contain    ${output}    ${intent}
    Should Contain    ${output}    ${match}

Verify no Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path ${path}
    Log    ${output}
    Should Contain    ${output}    ${intent}

Delete Config on node
    [Documentation]    Delete config from a node using gNMI.
    [Arguments]    ${node}    ${path}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --delete ${path}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Set Config on node
    [Documentation]    Delete config from a node using gNMI.
    [Arguments]    ${node}    ${path}    ${value}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} set --update-path ${path} --update-value ${value}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Delete Deviation CR
    [Documentation]    Delete the deviation CR on k8s
    [Arguments]    ${name}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl delete deviation.config.sdcio.dev/${name} -n ${SDCIO_RESOURCE_NAMESPACE}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Setup
    Run    echo 'setup executed'
    kubectl apply    ${CURDIR}/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    kubectl apply    ${CURDIR}/sros/intent1-sros.yaml
    kubectl patch    configset  intent1-sros    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent1-sros"
    kubectl apply    ${CURDIR}/sros/intent2-sros.yaml
    kubectl patch    configset  intent2-sros    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent2-sros"
    kubectl apply    ${CURDIR}/sros/intent3-sros.yaml
    kubectl patch    config    intent3-sros    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    kubectl apply    ${CURDIR}/sros/intent4-sros.yaml
    kubectl patch    config    intent4-sros    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-sros"


Cleanup
    Run    echo 'cleanup executed'
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-sros"
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-sros"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-sros"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${null}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${null}
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    Run Keyword If Any Tests Failed    Sleep    10s
