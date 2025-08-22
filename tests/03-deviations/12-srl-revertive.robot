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
${operation}            Deviation:revertive:implicit
${intent1}              "network-instance[name=vrf1]/admin-state"
${intent2}              "network-instance[name=vrf2]/admin-state"
${intent3}              "network-instance[name=vrf3]/admin-state"
${intent4}              "network-instance[name=vrf4]/admin-state"
${intent5}              "network-instance[name=vrf5]/admin-state"
${adminstate}           "network-instance/admin-state": "enable"

*** Test Cases ***
# Delete ConfigSet and Config one by one, from SRL nodes, we will have to wait for the syncPeriod to pass before deviations are calculated. After the syncPeriod, deviations should be 0 and Intent has to be recreated on the device.
${operation} - Delete ConfigSet intent1-srl on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Delete Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]"
    Run Keyword
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]"
    Run Keyword
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]"

Verify - ${operation} ConfigSet intent1-srl is gone on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Verify ConfigSet does not exist on nodes
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}

Verify - ${operation} ConfigSet intent1-srl is recreated on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    ...    ${adminstate}

${operation} - Delete ConfigSet intent2-srl on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Delete Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]"
    Run Keyword
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]"
    Run Keyword
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]"

Verify - ${operation} ConfigSet intent2-srl is gone on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Verify ConfigSet does not exist on nodes
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}

Verify - ${operation} ConfigSet intent2-srl is recreated on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    ...    ${adminstate}

${operation} - Delete Config intent3-srl on srl1
    Run Keyword
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf3]"

Verify - ${operation} Config intent3-srl is gone on srl1
    Run Keyword
    ...    Verify Config does not exist on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}

Verify - ${operation} Config intent3-srl is recreated on srl1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}
    ...    ${adminstate}

${operation} - Delete Config intent4-srl on srl2
    Run Keyword
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"

Verify - ${operation} Config intent4-srl is gone on srl2
    Run Keyword
    ...    Verify Config does not exist on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}

Verify - ${operation} Config intent4-srl is recreated on srl2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}
    ...    ${adminstate}

${operation} - Delete Config intent5-srl on srl3
    Run Keyword
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"

Verify - ${operation} Config intent5-srl is gone on srl3
    Run Keyword
    ...    Verify Config does not exist on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}

Verify - ${operation} Config intent5-srl is recreated on srl3
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}
    ...    ${adminstate}

# Delete ALL ConfigSet and Config from SRL nodes, we will have to wait for the syncPeriod to pass before deviations are calculated. After the syncPeriod, deviations should be 0 and Intent has to be recreated on the device.

${operation} - Delete All Config(Set) on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Delete Config on node
    ...    srl1
    ...    "/network-instance[name=vrf*]"
    Run Keyword
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf*]"
    Run Keyword
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf*]"

Verify - ${operation} all Config(Set) on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}
    ...    ${adminstate}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}
    ...    ${adminstate}

# Alter specific paths of the intent directly on the device, syncPeriod will have to pass by, verify recovery on the device (note: deviation counter should not increase)

${operation} - Adjust ConfigSet intent1-srl on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/1]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/1]/description"
    ...    "Deviation revertive test - override description intent1"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "100"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "1000"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/1]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/1]/description"
    ...    "Deviation revertive test - override description intent1"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "100"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "2000"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "disable"

Verify - ${operation} Adjust ConfigSet intent1-srl on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/1]/admin-state"
    ...    "Path": "interface[name=ethernet-1/1]/admin-state"
    ...    "interface/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/1]/description"
    ...    "Path": "interface[name=ethernet-1/1]/description"
    ...    "interface/description": "intent1"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/admin-state"
    ...    "Path": "network-instance[name=vrf1]/admin-state"
    ...    "network-instance/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 65001
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "enable"


${operation} - Adjust ConfigSet intent2-srl on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Deviation revertive test - override description intent2"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "200"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "2000"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Deviation revertive test - override description intent1"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "200"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "2000"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "disable"
Verify - ${operation} Adjust ConfigSet intent2-srl on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "Path": "interface[name=ethernet-1/2]/admin-state"
    ...    "interface/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Path": "interface[name=ethernet-1/2]/description"
    ...    "interface/description": "intent2-layer2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/admin-state"
    ...    "network-instance/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 65002
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "enable"

${operation} - Adjust Config intent3-srl on srl1
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/description"
    ...    "Deviation revertive test - override description intent3"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "300"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/protocols/bgp/autonomous-system"
    ...    "3000"
    Run Keyword
    ...    Set Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
Verify - ${operation} Adjust Config intent3-srl on srl1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/admin-state"
    ...    "Path": "interface[name=ethernet-1/3]/admin-state"
    ...    "interface/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/description"
    ...    "Path": "interface[name=ethernet-1/3]/description"
    ...    "interface/description": "intent3"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/3]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/admin-state"
    ...    "Path": "network-instance[name=vrf3]/admin-state"
    ...    "network-instance/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf3]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 65003
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf3]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "enable"

${operation} - Adjust Config intent4-srl on srl2
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/description"
    ...    "Deviation revertive test - override description intent4"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "400"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "4000"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "disable"
Verify - ${operation} Adjust Config intent4-srl on srl2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/admin-state"
    ...    "Path": "interface[name=ethernet-1/4]/admin-state"
    ...    "interface/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/description"
    ...    "Path": "interface[name=ethernet-1/4]/description"
    ...    "interface/description": "intent4"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/admin-state"
    ...    "network-instance/admin-state": "enable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 65004
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "enable"

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
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Set Config on node
    [Documentation]    Delete config from a node using gNMI.
    [Arguments]    ${node}    ${path}    ${value}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 --skip-verify -e PROTO -u ${SRL_USERNAME} -p ${SRL_PASSWORD} set --update-path ${path} --update-value ${value}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    RETURN    ${rc}    ${output}

Setup
    Run    echo 'setup executed'
    kubectl apply    ${CURDIR}/srl/intent1-srl.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-srl"
    kubectl apply    ${CURDIR}/srl/intent2-srl.yaml
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-srl"
    kubectl apply    ${CURDIR}/srl/intent3-srl.yaml
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-srl"
    kubectl apply    ${CURDIR}/srl/intent4-srl.yaml
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-srl"
    kubectl apply    ${CURDIR}/srl/intent5-srl.yaml
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent5-srl"


Cleanup
    Run    echo 'cleanup executed'
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-srl"
    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-srl"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-srl"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-srl"
    Delete Config    ${SDCIO_RESOURCE_NAMESPACE}    "intent5-srl"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]"
    ...    ${intent1}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]"
    ...    ${intent2}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    ...    ${intent3}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    ...    ${intent4}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify no Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    ...    ${intent5}
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl1
    ...    "/network-instance[name=vrf1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/1]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl1
    ...    "/network-instance[name=vrf2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/2]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl3
    ...    "/network-instance[name=vrf5]"
    Run Keyword If Any Tests Failed
    ...    Delete Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/5]"
    Run Keyword If Any Tests Failed    Sleep    10s

