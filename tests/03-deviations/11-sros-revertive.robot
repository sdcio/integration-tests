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
${operation}            Deviation:revertive:implicit
${intent1}              "service-name": "vprn123"
${intent2}              "service-name": "vprn234"
${intent3}              "service-name": "vprn789"
${intent4}              "service-name": "vprn987"
${adminstate}           "admin-state": "enable"
${customer}             "customer": "1"
${null}                 "configure/service/vprn": null


*** Test Cases ***
# Delete ConfigSet and Config one by one, from SROS nodes, we will have to wait for the syncPeriod to pass before deviations are calculated. After the syncPeriod, deviations should be 0 and Intent has to be recreated on the device.
${operation} - Delete ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}
    Run Keyword
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${null}
Verify - ${operation} ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    ${adminstate}

${operation} - Delete ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}
    Run Keyword
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${null}
Verify - ${operation} ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    ${adminstate}
${operation} - Delete Config intent3 on sr1
    Run Keyword
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${null}
Verify - ${operation} Config intent3 on sr1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    ${adminstate}
${operation} - Delete Config intent4 on sr2
    Run Keyword
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${null}
Verify - ${operation} Config intent4 on sr2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    ${adminstate}

# Delete ALL ConfigSet and Config from SROS nodes, we will have to wait for the syncPeriod to pass before deviations are calculated. After the syncPeriod, deviations should be 0 and Intent has to be recreated on the device.

${operation} - Delete All Config(Set) on ${SDCIO_SROS_NODES}
    Run Keyword
    ...    Delete Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=*]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=*]"
    ...    ${null}
    Run Keyword
    ...    Delete Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=*]"
    Run Keyword
    ...    Verify no Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=*]"
    ...    ${null}
Verify - ${operation} all Config(Set) on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    ${adminstate}

# Alter specific paths of the intent directly on the device, syncPeriod will have to pass by, verify recovery on the device (note: deviation counter should not increase)

${operation} - Adjust ConfigSet intent1 on ${SDCIO_SROS_NODES}
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
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "admin-state": "disable"
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 1101
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "customer": "2"
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
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "admin-state": "disable"
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 1101
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "customer": "2"
Verify - ${operation} Adjust ConfigSet intent1 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    "service-id": 101
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn123]"
    ...    ${intent1}
    ...    ${customer}

${operation} - Adjust ConfigSet intent2 on ${SDCIO_SROS_NODES}
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
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"
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
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "admin-state": "disable"
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 1102
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "customer": "2"
Verify - ${operation} Adjust ConfigSet intent2 on ${SDCIO_SROS_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    "service-id": 102
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/configure/service/vprn[service-name=vprn234]"
    ...    ${intent2}
    ...    ${customer}
${operation} - Adjust Config intent3 on sr1
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
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "admin-state": "disable"
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "service-id": 1103
    Run Keyword
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    "customer": "2"
Verify - ${operation} Adjust Config intent3 on sr1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr1
    ...    "/configure/service/vprn[service-name=vprn789]"
    ...    ${intent3}
    ...    ${adminstate}
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
    ...    ${customer}
${operation} - Adjust Config intent4 on sr2
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
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "admin-state": "disable"
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "service-id": 1104
    Run Keyword
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "customer": "2"
Verify - ${operation} Adjust Config intent4 on sr2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    "service-id": 104
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    sr2
    ...    "/configure/service/vprn[service-name=vprn987]"
    ...    ${intent4}
    ...    ${customer}

*** Keywords ***
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

Setup
    Run    echo 'setup executed'
    kubectl apply    ${CURDIR}/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    kubectl apply    ${CURDIR}/sros/intent1-sros-revertive.yaml
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent1-sros"
    kubectl apply    ${CURDIR}/sros/intent2-sros-revertive.yaml
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent2-sros"
    kubectl apply    ${CURDIR}/sros/intent3-sros-revertive.yaml
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    kubectl apply    ${CURDIR}/sros/intent4-sros-revertive.yaml
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
