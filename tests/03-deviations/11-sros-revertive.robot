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
${operation}            Deviation-revertive
${intent1}              "service-name": "vprn123"
${intent2}              "service-name": "vprn234"
${intent3}              "service-name": "vprn789"
${intent4}              "service-name": "vprn987"
${adminstate}           "admin-state": "disable"
${null}                 "configure/service/vprn": null


*** Test Cases ***
# Usecases
# implicit revertive
## Duplicate test cases below for Config, ConfigSet. 
## delete an intent from the device, Verify during sync period, verify recovery on the device (note: deviation counter should not increase)
## delete all intents from device, verify during sync period, verify recovery on the device (note: deviation counter should not increase)
## alter paths of the intent directly on the device, verify during sync period, verify recovery on the device (note: deviation counter should not increase)
## alter paths of the intent directly on the device, delete an intent against the k8s interface, verify recovery on the device (note: changes triggered on same target by other intent)

# explicit revertive
## same test cases as above, but patch the intents with a revertive: true flag.

# explicit non-revertive
## Duplicate test cases below for Config, ConfigSet. 
## create a non-revertive intent (patch), apply changes on the device, verify after sync period the deviation counter increases, dump the full output of the deviation. (deviation create)
## delete a revertive intent, verify during sync period, make sure the non-revertive intent is still unchanged (verify the deviation intent is applied)
## delete the deviation CR, verify during sync period, make sure the intent is back in it's original state (reject the deviation intent)
## patch the original intent CR partially, verify during sync period, make sure the deviation counter is reset to N-1, verify the state on the device matches the patched intent (accept the deviation partially)
## patch the original intent CR, verify during sync period, make sure the deviation counter is reset to 0, verify the state on the device matches the patched intent. (accept the deviation intent)

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

*** Keywords ***
Verify ConfigSet intent on nodes
    [Documentation]    Iterates through the SDCIO_SROS_NODES, validates if the output contains $intent and $adminstate for gNMI $path
    [Arguments]    ${path}    ${intent}    ${adminstate}
    FOR    ${node}    IN    @{SDCIO_SROS_NODES}
        Verify Config on node    ${node}    ${path}    ${intent}    ${adminstate}
    END

Verify Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}    ${adminstate}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --insecure -u ${SROS_USERNAME} -p ${SROS_PASSWORD} get --path ${path}
    Log    ${output}
    Should Contain    ${output}    ${intent}
    Should Contain    ${output}    ${adminstate}

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

Setup
    Run    echo 'setup executed'
    kubectl apply    ${CURDIR}/sros/customer.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "customer"
    kubectl apply    ${CURDIR}/sros/intent1-sros.yaml
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent1-sros"
    kubectl apply    ${CURDIR}/sros/intent2-sros.yaml
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent2-sros"
    kubectl apply    ${CURDIR}/sros/intent3-sros.yaml
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-sros"
    kubectl apply    ${CURDIR}/sros/intent4-sros.yaml
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
