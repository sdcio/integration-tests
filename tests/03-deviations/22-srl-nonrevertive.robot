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
${operation}            Deviation:nonrevertive
${intent1}              "network-instance[name=vrf1]/admin-state"
${intent2}              "network-instance[name=vrf2]/admin-state"
${intent3}              "network-instance[name=vrf3]/admin-state"
${intent4}              "network-instance[name=vrf4]/admin-state"
${intent5}              "network-instance[name=vrf5]/admin-state"

*** Test Cases ***

# Non-revertive ConfigSet intent1-srl is applied, change values on device, witness the deviation counter increase, verify the ConfigSet on the devices.

${operation} - Create Deviation: adjust config (intent1-srl) on ${SDCIO_SRL_NODES}
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
    ...    "1000"
    Run Keyword
    ...    Set Config on node
    ...    srl2
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/1]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/1]/description"
    ...    "Deviation revertive test - override description intent1"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "100"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "1000"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
Verify - ${operation} Deviation counter is 6 on intent1-srl-srl1, intent1-srl-srl2 and intent1-srl-srl3 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-srl-srl1
    ...    6
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-srl-srl2
    ...    6
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-srl-srl3
    ...    6
Verify - ${operation} Deviations (intent1-srl) are persistently applied on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/1]/admin-state"
    ...    "Path": "interface[name=ethernet-1/1]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/1]/description"
    ...    "Path": "interface[name=ethernet-1/1]/description"
    ...    "interface/description": "Deviation revertive test - override description intent1"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/1]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 100
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/admin-state"
    ...    "Path": "network-instance[name=vrf1]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf1]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 1000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf1]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

# Reject the intent (delete the deviation CR), verify the intent is back in it's original state.
Reject Deviation - ${operation} Delete the Deviation CR (intent1-srl) applied on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-srl-srl1
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-srl-srl2
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-srl-srl3

Verify - ${operation} Rejected Deviations (intent1-srl) are now gone on ${SDCIO_SRL_NODES}
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

Verify - ${operation} Deviation counter == 0 for intent1-srl-srl1, intent1-srl-srl2 and intent1-srl-srl3 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-srl-srl1
    ...    0
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-srl-srl2
    ...    0
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent1-srl-srl3
    ...    0

${operation} - Create Deviation: adjust config (intent2-srl) on ${SDCIO_SRL_NODES}
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
    ...    "Deviation revertive test - override description intent2"
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
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Deviation revertive test - override description intent2"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "200"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "disable"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "2000"
    Run Keyword
    ...    Set Config on node
    ...    srl3
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "disable"
Verify - ${operation} Deviation counter is 6 on intent2-srl-srl1, intent2-srl-srl2 and intent2-srl-srl3 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl1
    ...    6
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl2
    ...    6
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl3
    ...    6
Verify - ${operation} Deviations (intent2-srl) are persistently applied on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "Path": "interface[name=ethernet-1/2]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Path": "interface[name=ethernet-1/2]/description"
    ...    "interface/description": "Deviation revertive test - override description intent2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 200
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 2000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"


# Accept the deviation (patch the original intent CR), verify the deviation counter is reset to 0, verify the state on the device matches the patched intent.
Partially Accept Deviation - ${operation} Patch intent2-srl applied on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    kubectl patch
    ...    configset
    ...    intent2-srl
    ...    '{"spec": {"config":[{"path":"/","value":{"interface":[{"admin-state":"disable","description":"Deviation revertive test - override description intent2","name":"ethernet-1/2","subinterface":[{"admin-state":"enable","index":0,"ipv4":{"address":[{"ip-prefix":"192.168.2.1/24"}],"admin-state":"enable","unnumbered":{"admin-state":"disable"}},"ipv6":{"address":[{"ip-prefix":"fd00:0:0:2::1/64"}],"admin-state":"enable"},"type":"routed","vlan":{"encap":{"single-tagged":{"vlan-id":200}}}}],"vlan-tagging":true}],"network-instance":[{"admin-state":"enable","description":"Intent2 Network-instance","interface":[{"name":"ethernet-1/2.0"}],"name":"vrf2","protocols":{"bgp":{"admin-state":"enable","afi-safi":[{"admin-state":"enable","afi-safi-name":"ipv4-unicast"},{"admin-state":"enable","afi-safi-name":"ipv6-unicast"}],"autonomous-system":65002,"router-id":"2.2.2.2"}},"type":"ip-vrf"}]}}],"priority":10,"revertive":false,"target":{"targetSelector":{"matchLabels":{"sdcio.dev/device":"srl"}}}}}'

Verify - ${operation} Deviation counter is 2 on intent2-srl-srl1, intent2-srl-srl2 and intent2-srl-srl3 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl1
    ...    3
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl2
    ...    3
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl3
    ...    3
    
Verify - ${operation} Deviations ConfigSet intent2-srl are partially accepted on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "Path": "interface[name=ethernet-1/2]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Path": "interface[name=ethernet-1/2]/description"
    ...    "interface/description": "Deviation revertive test - override description intent2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 200
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 2000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

Fully Accept Deviation - ${operation} Patch intent2-srl applied on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    kubectl patch
    ...    configset
    ...    intent2-srl
    ...    '{"spec": {"config":[{"path":"/","value":{"interface":[{"admin-state":"disable","description":"Deviation revertive test - override description intent2","name":"ethernet-1/2","subinterface":[{"admin-state":"enable","index":0,"ipv4":{"address":[{"ip-prefix":"192.168.2.1/24"}],"admin-state":"enable","unnumbered":{"admin-state":"disable"}},"ipv6":{"address":[{"ip-prefix":"fd00:0:0:2::1/64"}],"admin-state":"enable"},"type":"routed","vlan":{"encap":{"single-tagged":{"vlan-id":200}}}}],"vlan-tagging":true}],"network-instance":[{"admin-state":"disable","description":"Intent2 Network-instance","interface":[{"name":"ethernet-1/2.0"}],"name":"vrf2","protocols":{"bgp":{"admin-state":"enable","afi-safi":[{"admin-state":"disable","afi-safi-name":"ipv4-unicast"},{"admin-state":"enable","afi-safi-name":"ipv6-unicast"}],"autonomous-system":2000,"router-id":"2.2.2.2"}},"type":"ip-vrf"}]}}],"priority":10,"revertive":false,"target":{"targetSelector":{"matchLabels":{"sdcio.dev/device":"srl"}}}}}'

# WorkAround bug Wim, explicitly delete the deviation CR, as the counter does not go to 0 after patching the intent CR
WorkAround Deviation - ${operation} Delete the Deviation CR (intent2-srl) applied on ${SDCIO_SRL_NODES}
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-srl-srl1
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-srl-srl2
    Run Keyword
    ...    Delete Deviation CR
    ...    intent1-srl-srl3

Verify - ${operation} Deviation counter is 0 on intent2-srl1, intent2-srl2 and intent2-srl3 on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl1
    ...    0
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl2
    ...    0
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent2-srl-srl3
    ...    0
    
Verify - ${operation} Deviations ConfigSet intent2-srl are fully accepted on ${SDCIO_SRL_NODES}
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/admin-state"
    ...    "Path": "interface[name=ethernet-1/2]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/description"
    ...    "Path": "interface[name=ethernet-1/2]/description"
    ...    "interface/description": "Deviation revertive test - override description intent2"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/2]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 200
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 2000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify ConfigSet intent on nodes
    ...    "/network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf2]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

${operation} - Create Deviation: adjust config (intent3-srl) on srl1
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

Verify - ${operation} Deviation counter is 6 on intent3-srl on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent3-srl
    ...    6

Verify - ${operation} Deviations (intent3-srl) are persistently applied on srl1
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/admin-state"
    ...    "Path": "interface[name=ethernet-1/3]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/description"
    ...    "Path": "interface[name=ethernet-1/3]/description"
    ...    "interface/description": "Deviation revertive test - override description intent3"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/interface[name=ethernet-1/3]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/3]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 300
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/admin-state"
    ...    "Path": "network-instance[name=vrf3]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf3]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 3000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl1
    ...    "/network-instance[name=vrf3]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf3]/protocols/bgp/afi-safi[afi-safi-name=ipv4-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

# Reject the intent (delete the deviation CR), verify the intent is back in it's original state.
Reject Deviation - ${operation} Delete the Deviation CR intent3-srl applied on srl1
    Run Keyword
    ...    Delete Deviation CR
    ...    intent3-srl

Verify - ${operation} Rejected Deviations (intent3-srl) is now gone on srl1
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
Verify - ${operation} Deviation counter is reset intent3-srl on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent3-srl
    ...    0

${operation} - Create Deviation: adjust config (intent4-srl) on srl2
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

Verify - ${operation} Deviation counter is 6 on intent4-srl on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent4-srl
    ...    6

Verify - ${operation} Deviations (intent4-srl) are persistently applied on srl2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/admin-state"
    ...    "Path": "interface[name=ethernet-1/4]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/description"
    ...    "Path": "interface[name=ethernet-1/4]/description"
    ...    "interface/description": "Deviation revertive test - override description intent4"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 400
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 4000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

# Accept the deviation (patch the original intent CR), verify the deviation counter is reset to 0, verify the state on the device matches the patched intent.

Partially Accept Deviation - ${operation} Patch intent4-srl applied on srl2
    Run Keyword
    ...    kubectl patch
    ...    config
    ...    intent4-srl
    ...    '{"spec": {"config":[{"path":"/","value":{"interface":[{"admin-state":"disable","description":"Deviation revertive test - override description intent4","name":"ethernet-1/4","subinterface":[{"admin-state":"enable","index":0,"ipv4":{"address":[{"ip-prefix":"192.168.4.1/24"}],"admin-state":"enable","unnumbered":{"admin-state":"disable"}},"ipv6":{"address":[{"ip-prefix":"fd00:0:0:4::1/64"}],"admin-state":"enable"},"type":"routed","vlan":{"encap":{"single-tagged":{"vlan-id":400}}}}],"vlan-tagging":true}],"network-instance":[{"admin-state":"enable","description":"Intent4 Network-instance","interface":[{"name":"ethernet-1/4.0"}],"name":"vrf4","protocols":{"bgp":{"admin-state":"enable","afi-safi":[{"admin-state":"enable","afi-safi-name":"ipv4-unicast"},{"admin-state":"enable","afi-safi-name":"ipv6-unicast"}],"autonomous-system":65004,"router-id":"4.4.4.4"}},"type":"ip-vrf"}]}}],"priority":10,"revertive":false}}'

Verify - ${operation} Deviation counter is 3 on intent4-srl on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent4-srl
    ...    3

Verify - ${operation} Deviations Config intent4-srl is fully accepted on srl2
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/admin-state"
    ...    "Path": "interface[name=ethernet-1/4]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/description"
    ...    "Path": "interface[name=ethernet-1/4]/description"
    ...    "interface/description": "Deviation revertive test - override description intent4"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 400
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 4000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

Fully Accept Deviation - ${operation} Patch intent4-srl applied on srl2
    Run Keyword
    ...    kubectl patch
    ...    config
    ...    intent4-srl
    ...    '{"spec": {"config":[{"path":"/","value":{"interface":[{"admin-state":"disable","description":"Deviation revertive test - override description intent4","name":"ethernet-1/4","subinterface":[{"admin-state":"enable","index":0,"ipv4":{"address":[{"ip-prefix":"192.168.4.1/24"}],"admin-state":"enable","unnumbered":{"admin-state":"disable"}},"ipv6":{"address":[{"ip-prefix":"fd00:0:0:4::1/64"}],"admin-state":"enable"},"type":"routed","vlan":{"encap":{"single-tagged":{"vlan-id":400}}}}],"vlan-tagging":true}],"network-instance":[{"admin-state":"disable","description":"Intent4 Network-instance","interface":[{"name":"ethernet-1/4.0"}],"name":"vrf4","protocols":{"bgp":{"admin-state":"enable","afi-safi":[{"admin-state":"enable","afi-safi-name":"ipv4-unicast"},{"admin-state":"disable","afi-safi-name":"ipv6-unicast"}],"autonomous-system":4000,"router-id":"4.4.4.4"}},"type":"ip-vrf"}]}}],"priority":10,"revertive":false}}'

# WorkAround bug Wim, explicitly delete the deviation CR, as the counter does not go to 0 after patching the intent CR
WorkAround Deviation - ${operation} Delete the Deviation CR intent4-srl applied on srl2
    Run Keyword
    ...    Delete Deviation CR
    ...    intent4-srl

Verify - ${operation} Deviation counter is 0 on intent4-srl on k8s
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Deviation on k8s
    ...    intent4-srl
    ...    0

Verify - ${operation} Deviations Config intent4-srl is fully accepted on srl2
   Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/admin-state"
    ...    "Path": "interface[name=ethernet-1/4]/admin-state"
    ...    "interface/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/description"
    ...    "Path": "interface[name=ethernet-1/4]/description"
    ...    "interface/description": "Deviation revertive test - override description intent4"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "Path": "interface[name=ethernet-1/4]/subinterface[index=0]/vlan/encap/single-tagged/vlan-id"
    ...    "interface/subinterface/vlan/encap/single-tagged/vlan-id": 400
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/admin-state"
    ...    "network-instance/admin-state": "disable"
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/autonomous-system"
    ...    "network-instance/protocols/bgp/autonomous-system": 4000
    Wait Until Keyword Succeeds
    ...    2min
    ...    10s
    ...    Verify Config on node
    ...    srl2
    ...    "/network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "Path": "network-instance[name=vrf4]/protocols/bgp/afi-safi[afi-safi-name=ipv6-unicast]/admin-state"
    ...    "network-instance/protocols/bgp/afi-safi/admin-state": "disable"

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
    ...    gnmic -a ${${node}} -p 57400 --skip-verify -e JSON_IETF -u ${SRL_USERNAME} -p ${SRL_PASSWORD} set --update-path ${path} --update-value ${value}
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
    kubectl apply    ${CURDIR}/srl/intent1-srl.yaml
    kubectl patch    configset    intent1-srl    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent1-srl"
    kubectl apply    ${CURDIR}/srl/intent2-srl.yaml
    kubectl patch    configset    intent2-srl    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds    2min    10s    ConfigSet Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent2-srl"
    kubectl apply    ${CURDIR}/srl/intent3-srl.yaml
    kubectl patch    config    intent3-srl    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent3-srl"
    kubectl apply    ${CURDIR}/srl/intent4-srl.yaml
    kubectl patch    config    intent4-srl    '{"spec": {"revertive": false}}'
    Wait Until Keyword Succeeds    2min    10s    Config Check Ready    ${SDCIO_RESOURCE_NAMESPACE}    "intent4-srl"
    kubectl apply    ${CURDIR}/srl/intent5-srl.yaml
    kubectl patch    config    intent5-srl    '{"spec": {"revertive": false}}'
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
