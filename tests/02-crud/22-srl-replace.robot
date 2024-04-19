*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup


*** Variables ***
@{SDCIO_SRL_NODES}      srl1    srl2    srl3
${operation}            Replace
${intent1-orig}         "network-instance[name=vrf1]/admin-state"
${intent2-orig}         "network-instance[name=vrf2]/admin-state"
${intent3-orig}         "network-instance[name=vrf3]/admin-state"
${intent4-orig}         "network-instance[name=vrf4]/admin-state"
${intent5-orig}         "network-instance[name=vrf5]/admin-state"
${intent1}              "network-instance[name=vrf11]/admin-state"
${intent2}              "network-instance[name=vrf12]/admin-state"
${intent3}              "network-instance[name=vrf13]/admin-state"
${intent4}              "network-instance[name=vrf14]/admin-state"
${intent5}              "network-instance[name=vrf15]/admin-state"
${adminstate}           "network-instance/admin-state": "enable"


*** Test Cases ***
${operation} - ConfigSet intent1 on ${SDCIO_SRL_NODES}
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/srl/intent1-srl-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} ConfigSet intent1 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent1-srl"

Verify - ${operation} ConfigSet intent1 on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf11]"
    ...    ${intent1}
    ...    ${adminstate}

Verify - ${operation} ConfigSet intent1 on ${SDCIO_SRL_NODES} no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet does not exist on nodes
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1-orig}

${operation} - ConfigSet intent2 on ${SDCIO_SRL_NODES}
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/srl/intent2-srl-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} ConfigSet intent2 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent2-srl"

Verify - ${operation} ConfigSet intent2 on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf12]"
    ...    ${intent2}
    ...    ${adminstate}

Verify - ${operation} ConfigSet intent2 on ${SDCIO_SRL_NODES} no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify ConfigSet does not exist on nodes
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2-orig}

${operation} - Config intent3 on srl1
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/srl/intent3-srl-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent3 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent3-srl"

Verify - ${operation} Config intent3 on srl1
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf13]"
    ...    ${intent3}
    ...    ${adminstate}

Verify - ${operation} Config intent3 on srl1 no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config does not exist on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3-orig}

${operation} - Config intent4 on srl2
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/srl/intent4-srl-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent4 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent4-srl"

Verify - ${operation} Config intent4 on srl2
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf14]"
    ...    ${intent4}
    ...    ${adminstate}

Verify - ${operation} Config intent4 on srl2 no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config does not exist on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4-orig}

${operation} - Config intent5 on srl3
    Log    ${CURDIR}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${CURDIR}/srl/intent5-srl-replace.yaml
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Verify - ${operation} Config intent5 on k8s
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    "intent5-srl"

Verify - ${operation} Config intent5 on srl3
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config on node
    ...    srl3
    ...    "/network-instance[name=vrf15]"
    ...    ${intent5}
    ...    ${adminstate}

Verify - ${operation} Config intent5 on srl3 no longer exists
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify Config does not exist on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5-orig}


*** Keywords ***
Verify ConfigSet intent on nodes
    [Documentation]    Iterates through the SDCIO_SRL_NODES, validates if the output contains $intent and $adminstate for gNMI $path
    [Arguments]    ${path}    ${intent}    ${adminstate}
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Verify Config on node    ${node}    ${path}    ${intent}    ${adminstate}
    END

Verify Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}    ${adminstate}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --skip-verify -e PROTO -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path ${path}
    Log    ${output}
    Should Contain    ${output}    ${intent}
    Should Contain    ${output}    ${adminstate}

Verify no Config on node
    [Documentation]    Validate if Config has been applied to a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --skip-verify -e PROTO -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path ${path}
    Log    ${output}
    Should Not Contain    ${output}    ${intent}

Verify ConfigSet does not exist on nodes
    [Documentation]    Iterates through the SDCIO_SRL_NODES, validates if the output does not contains $intent for gNMI $path
    [Arguments]    ${path}    ${intent}
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Verify Config does not exist on node    ${node}    ${path}    ${intent}
    END

Verify Config does not exist on node
    [Documentation]    Validate if Config does not exist on a node, through collecting a gNMI path
    [Arguments]    ${node}    ${path}    ${intent}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --skip-verify -e PROTO -u ${SRL_USERNAME} -p ${SRL_PASSWORD} get --type CONFIG --path ${path}
    Log    ${output}
    Should Not Contain    ${output}    ${intent}

Delete Config on node
    [Documentation]    Delete config from a node using gNMI.
    [Arguments]    ${node}    ${path}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --skip-verify -e PROTO -u ${SRL_USERNAME} -p ${SRL_PASSWORD} set --delete ${path}
    Log ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Setup
    Run    echo 'setup executed'
    kubectl apply    ${CURDIR}/srl/intent1-srl.yaml
    Wait Until Keyword Succeeds    1min    5s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-srl"
    kubectl apply    ${CURDIR}/srl/intent2-srl.yaml
    Wait Until Keyword Succeeds    1min    5s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-srl"
    kubectl apply    ${CURDIR}/srl/intent3-srl.yaml
    Wait Until Keyword Succeeds    1min    5s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-srl"
    kubectl apply    ${CURDIR}/srl/intent4-srl.yaml
    Wait Until Keyword Succeeds    1min    5s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-srl"
    kubectl apply    ${CURDIR}/srl/intent5-srl.yaml
    Wait Until Keyword Succeeds    1min    5s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent5-srl"

Cleanup
    Run    echo 'cleanup executed'
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-srl"
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-srl"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-srl"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-srl"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent5-srl"
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf11]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf11]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf11]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf12]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf12]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf12]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf13]"
    ...    ${intent3}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf14]"
    ...    ${intent4}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf15]"
    ...    ${intent5}
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/network-instance[name=vrf11]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/network-instance[name=vrf11]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/network-instance[name=vrf11]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/network-instance[name=vrf12]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/network-instance[name=vrf12]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/network-instance[name=vrf12]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/network-instance[name=vrf13]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/interface[name=ethernet-1/3]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/network-instance[name=vrf14]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/interface[name=ethernet-1/4]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/network-instance[name=vrf15]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/interface[name=ethernet-1/5]"
    Run Keyword If Any Tests Failed    Sleep    5s
