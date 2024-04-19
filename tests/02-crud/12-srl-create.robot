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
${operation}            Create
${intent1}              "network-instance[name=vrf1]/admin-state"
${intent2}              "network-instance[name=vrf2]/admin-state"
${intent3}              "network-instance[name=vrf3]/admin-state"
${intent4}              "network-instance[name=vrf4]/admin-state"
${intent5}              "network-instance[name=vrf5]/admin-state"
${adminstate}           "network-instance/admin-state": "enable"


*** Test Cases ***
${operation} - ConfigSet intent1 on ${SDCIO_SRL_NODES}
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/srl/intent1-srl.yaml

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
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    ...    ${adminstate}

${operation} - ConfigSet intent2 on ${SDCIO_SRL_NODES}
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/srl/intent2-srl.yaml

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
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    ...    ${adminstate}

${operation} - Config intent3 on srl3
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/srl/intent3-srl.yaml

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
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}
    ...    ${adminstate}

${operation} - Config intent4 on srl2
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/srl/intent4-srl.yaml

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
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}
    ...    ${adminstate}

${operation} - Config intent5 on srl3
    ${rc}    ${output} =    kubectl apply    ${CURDIR}/srl/intent5-srl.yaml

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
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}
    ...    ${adminstate}


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
    Wait Until Keyword Succeeds    15min    5s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    srl1
    Wait Until Keyword Succeeds    15min    5s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    srl2
    Wait Until Keyword Succeeds    15min    5s    Targets Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    srl3
    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}
    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}
    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}

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
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}
    Wait Until Keyword Succeeds
    ...    1min
    ...    5s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/network-instance[name=vrf1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/network-instance[name=vrf1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/network-instance[name=vrf1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/network-instance[name=vrf2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/network-instance[name=vrf2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/network-instance[name=vrf2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/network-instance[name=vrf3]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl1}
    ...    "/interface[name=ethernet-1/3]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/network-instance[name=vrf4]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl2}
    ...    "/interface[name=ethernet-1/4]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/network-instance[name=vrf5]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    ${srl3}
    ...    "/interface[name=ethernet-1/5]"
    Run Keyword If Any Tests Failed    Sleep    5s
