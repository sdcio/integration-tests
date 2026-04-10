*** Settings ***
Library             OperatingSystem
Library             Process
Library             Collections
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/gnmic.robot
Resource            ../Keywords/deviation.robot
Resource            ../Keywords/discovery.robot

Suite Setup         Setup
Suite Teardown      Run Keyword    Cleanup

*** Variables ***
@{SDCIO_SRL_NODES}          srl1       srl3    srl2 
${retry}                    10s
${eventual_timeout}         4min
${discovery_timeout}        10min
${options}                  --skip-verify -e PROTO
${optionsSet}               --skip-verify -e JSON_IETF
@{SRL_PROFILE_FILES}
...                         ${CURDIR}/../01-crs/connection-profiles/conn_profile_srl_gnmi_proto.yaml
...                         ${CURDIR}/../01-crs/connection-profiles/conn_profile_srl_gnmi_jsonietf.yaml
...                         ${CURDIR}/../01-crs/sync-profiles/sync_profile_srl_gnmi_get.yaml
...                         ${CURDIR}/../01-crs/sync-profiles/sync_profile_srl_gnmi_onchange.yaml
...                         ${CURDIR}/../01-crs/sync-profiles/sync_profile_srl_gnmi_onchange_jsonietf.yaml
@{SRL_ONCHANGE_DISCOVERY_RULE_FILES}
...                         ${CURDIR}/../01-crs/discovery-rule/discovery_srl_gnmi_srl1_proto_onchange.yaml
...                         ${CURDIR}/../01-crs/discovery-rule/discovery_srl_gnmi_srl2_jsonietf_onchange.yaml
...                         ${CURDIR}/../01-crs/discovery-rule/discovery_srl_gnmi_srl3_jsonietf_onchange.yaml
@{SRL_ONCHANGE_DISCOVERY_RULE_NAMES}
...                         dr-srl-gnmi-srl1-proto-onchange
...                         dr-srl-gnmi-srl2-jsonietf-onchange
...                         dr-srl-gnmi-srl3-jsonietf-onchange
${SRL_DEFAULT_DISCOVERY_RULE_FILE}    ${CURDIR}/../01-crs/discovery-rule/discovery_srl_gnmi_prefix.yaml

*** Test Cases ***
Verify SRL onChange discovery uses mixed encodings
    Assert SRL OnChange Discovery State

Detect SRL deviations under onChange across mixed encodings
    Apply SRL Intent1 ConfigSet
    Create SRL Intent1 Deviations
    Verify SRL Intent1 Deviations

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${profile_file}    IN    @{SRL_PROFILE_FILES}
        kubectl apply    ${profile_file}
    END
    Delete Discovery Rules If Present    dr-srl-gnmi-prefix
    Delete Discovery Rules If Present    @{SRL_ONCHANGE_DISCOVERY_RULE_NAMES}
    Apply Discovery Rules    @{SRL_ONCHANGE_DISCOVERY_RULE_FILES}
    Assert SRL OnChange Discovery State

Cleanup
    Run    echo 'cleanup executed'
    Cleanup SRL Intent And Deviations
    Run Keyword If Any Tests Failed    DeleteAll
    Delete Discovery Rules If Present    @{SRL_ONCHANGE_DISCOVERY_RULE_NAMES}
    Apply Discovery Rules    ${SRL_DEFAULT_DISCOVERY_RULE_FILE}
    Assert SRL Default Discovery State

Assert SRL OnChange Discovery State
    Wait Until Keyword Succeeds
    ...    ${discovery_timeout}
    ...    ${retry}
    ...    Target Check Ready With Profiles
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    srl1
    ...    test-srl-gnmi-proto
    ...    test-srl-gnmi-onchange
    Wait Until Keyword Succeeds
    ...    ${discovery_timeout}
    ...    ${retry}
    ...    Target Check Ready With Profiles
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    srl2
    ...    test-srl-gnmi-jsonietf
    ...    test-srl-gnmi-onchange-jsonietf
    Wait Until Keyword Succeeds
    ...    ${discovery_timeout}
    ...    ${retry}
    ...    Target Check Ready With Profiles
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    srl3
    ...    test-srl-gnmi-jsonietf
    ...    test-srl-gnmi-onchange-jsonietf

Assert SRL Default Discovery State
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds
        ...    ${discovery_timeout}
        ...    ${retry}
        ...    Target Check Ready With Profiles
        ...    ${SDCIO_RESOURCE_NAMESPACE}
        ...    ${node}
        ...    test-srl-gnmi-proto
        ...    test-srl-gnmi-get
    END

Apply SRL Intent1 ConfigSet
    kubectl apply    ${CURDIR}/input/srl/intent1-srl.yaml
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    intent1-srl

Create SRL Intent1 Deviations
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Set Config on node via file
        ...    ${node}
        ...    ${optionsSet}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    /
        ...    ${CURDIR}/input/srl/deviations-intent1.json
    END

Verify SRL Intent1 Deviations
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Wait Until Keyword Succeeds
        ...    ${eventual_timeout}
        ...    ${retry}
        ...    Verify Deviation on k8s
        ...    intent1-srl-${node}
        ...    6
    END

Cleanup SRL Intent And Deviations
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Run Keyword And Ignore Error    Delete Deviation CR    intent1-srl-${node}
    END
    ${status}    ${message} =    Run Keyword And Ignore Error
    ...    Delete ConfigSet
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    intent1-srl
    Run Keyword If    '${status}' == 'PASS'
    ...    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Run Keyword And Expect Error
    ...    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configsets.config.sdcio.dev intent1-srl

DeleteAll
    FOR    ${node}    IN    @{SDCIO_SRL_NODES}
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    /network-instance[name=vrf*]
        Delete Config from node
        ...    ${node}
        ...    ${options}
        ...    ${SRL_USERNAME}
        ...    ${SRL_PASSWORD}
        ...    /interface[name=ethernet-1/*]
    END