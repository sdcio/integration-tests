*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/k8s/kubectl.robot
Resource            ../Keywords/targets.robot
Resource            ../Keywords/config.robot
Resource            ../Keywords/gnmic.robot
Resource            ../Keywords/deviation.robot
Resource            ../Keywords/discovery.robot

Suite Setup         Setup
# Suite Teardown      Run Keyword    Cleanup

*** Variables ***
${retry}                    10s
${eventual_timeout}         4min
${discovery_timeout}        10min
${options}                  --insecure -e JSON
${filter}                   "configure/service/vprn"
@{SROS_PROFILE_FILES}
...                         ${CURDIR}/../01-crs/connection-profiles/conn_profile_sros_gnmi.yaml
...                         ${CURDIR}/../01-crs/sync-profiles/sync_profile_sros_gnmi.yaml
...                         ${CURDIR}/../01-crs/sync-profiles/sync_profile_sros_gnmi_onchange.yaml
@{SROS_ONCHANGE_DISCOVERY_RULE_FILES}
...                         ${CURDIR}/../01-crs/discovery-rule/discovery_sros_gnmi_sr2_onchange.yaml
@{SROS_ONCHANGE_DISCOVERY_RULE_NAMES}
...                         dr-sros-gnmi-sr2-onchange
${SROS_DEFAULT_DISCOVERY_RULE_FILE}    ${CURDIR}/../01-crs/discovery-rule/discovery_sros_gnmi_prefix.yaml

*** Test Cases ***
Verify SROS gNMI onChange discovery becomes active
    Assert SROS OnChange Discovery State

Detect SROS deviations under gNMI onChange
    Apply SROS Customer Context
    Apply SROS Intent4 Config
    Create SROS Intent4 Deviation
    Verify SROS Intent4 Deviation

*** Keywords ***
Setup
    Run    echo 'setup executed'
    FOR    ${profile_file}    IN    @{SROS_PROFILE_FILES}
        kubectl apply    ${profile_file}
    END
    Delete Discovery Rules If Present    dr-sros-gnmi-sr2
    Delete Discovery Rules If Present    @{SROS_ONCHANGE_DISCOVERY_RULE_NAMES}
    Apply Discovery Rules    @{SROS_ONCHANGE_DISCOVERY_RULE_FILES}
    Assert SROS OnChange Discovery State

Cleanup
    Run    echo 'cleanup executed'
    Cleanup SROS Intent And Deviations
    Run Keyword If Any Tests Failed    DeleteAll
    Delete Discovery Rules If Present    @{SROS_ONCHANGE_DISCOVERY_RULE_NAMES}
    Apply Discovery Rules    ${SROS_DEFAULT_DISCOVERY_RULE_FILE}
    Assert SROS Default Discovery State

Assert SROS OnChange Discovery State
    Wait Until Keyword Succeeds
    ...    ${discovery_timeout}
    ...    ${retry}
    ...    Target Check Ready With Profiles
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    sr2
    ...    test-sros-gnmi
    ...    test-sros-gnmi-onchange-json

Assert SROS Default Discovery State
    Wait Until Keyword Succeeds
    ...    ${discovery_timeout}
    ...    ${retry}
    ...    Target Check Ready With Profiles
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    sr2
    ...    test-sros-gnmi
    ...    test-sros-gnmi-getconfig

Apply SROS Customer Context
    kubectl apply    ${CURDIR}/input/sros/customer.yaml
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    ConfigSet Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    customer

Apply SROS Intent4 Config
    kubectl apply    ${CURDIR}/input/sros/intent4-sros.yaml
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Config Check Ready
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    intent4-sros

Create SROS Intent4 Deviation
    Set Config on node via file
    ...    sr2
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    /configure/service/vprn[service-name=vprn987]/
    ...    ${CURDIR}/input/sros/deviations-intent4.json
    Verify SROS Intent4 Drift On Device

Verify SROS Intent4 Drift On Device
    ${admin_state} =    Get Config from node
    ...    sr2
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    /configure/service/vprn[service-name=vprn987]/admin-state
    ${admin_state_text} =    Convert To String    ${admin_state}
    Should Contain    ${admin_state_text}    disable
    ${customer} =    Get Config from node
    ...    sr2
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    /configure/service/vprn[service-name=vprn987]/customer
    ${customer_text} =    Convert To String    ${customer}
    Should Contain    ${customer_text}    2

Verify SROS Intent4 Deviation
    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Verify Deviation on k8s
    ...    intent4-sros
    ...    3

Cleanup SROS Intent And Deviations
    Run Keyword And Ignore Error    Delete Deviation CR    intent4-sros
    ${status}    ${message} =    Run Keyword And Ignore Error
    ...    Delete Config
    ...    ${SDCIO_RESOURCE_NAMESPACE}
    ...    intent4-sros
    Run Keyword If    '${status}' == 'PASS'
    ...    Wait Until Keyword Succeeds
    ...    ${eventual_timeout}
    ...    ${retry}
    ...    Run Keyword And Expect Error
    ...    *
    ...    kubectl get    -n ${SDCIO_RESOURCE_NAMESPACE} configs.config.sdcio.dev intent4-sros
    Run Keyword And Ignore Error    Delete ConfigSet    ${SDCIO_RESOURCE_NAMESPACE}    customer

DeleteAll
    Delete Config from node
    ...    sr2
    ...    ${options}
    ...    ${SROS_USERNAME}
    ...    ${SROS_PASSWORD}
    ...    /configure/service/vprn[service-name=*]