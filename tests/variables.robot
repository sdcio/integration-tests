*** Variables ***
${CERT_MANAGER_VERSION}                                             %{CERT_MANAGER_VERSION=v1.14.1}
${SDCIO_SYSTEM_NAMESPACE}                                           network-system
${SDCIO_RESOURCE_NAMESPACE}                                         default
${SDCIO_COLOCATED_DEPLOYMENT}                                       config-server
@{SDCIO_APIServices}                                                v1alpha1.config.sdcio.dev    v1alpha1.inv.sdcio.dev
${SDCIO_CONFIG_SERVER_REPO_PATH}                                    ./config-server

# Secrets
${SDCIO_CONFIG_SERVER_SECRETS_FILES_BASE}                           ${SDCIO_CONFIG_SERVER_REPO_PATH}/example/secrets
# This is intentionally left empty as there are no custom schema's to be tested yet.
@{SDCIO_CONFIG_SERVER_SECRETS_FILES}                                @{EMPTY}

${SDCIO_INTEGRATION_TESTS_SECRETS_FILES_BASE}                       ${CURDIR}/01-crs/secrets
# This is intentionally left empty as there are no custom schema's to be tested yet.
@{SDCIO_INTEGRATION_TESTS_SECRETS_FILES}                            secret-srl.yaml    secret-sros.yaml

# Schemas
${SDCIO_CONFIG_SERVER_SCHEMA_FILES_BASE}                            ${SDCIO_CONFIG_SERVER_REPO_PATH}/example/schemas
@{SDCIO_CONFIG_SERVER_SCHEMA_FILES}
...                                                                 schema-nokia-sros-24.10.yaml
...                                                                 schema-nokia-srl-24.10.1.yaml

${SDCIO_INTEGRATION_TESTS_SCHEMA_FILES_BASE}                        ${CURDIR}/01-crs/schema
# This is intentionally left empty as there are no custom schema's to be tested yet.
@{SDCIO_INTEGRATION_TESTS_SCHEMA_FILES}
...                                                                 schema-nokia-sros-25.7.yaml
...                                                                 schema-nokia-srl-25.7.1.yaml

# TargetConnectionProfiles
${SDCIO_CONFIG_SERVER_TARGETCONNECTIONPROFILE_FILES_BASE}           ${SDCIO_CONFIG_SERVER_REPO_PATH}/example/connection-profiles
@{SDCIO_CONFIG_SERVER_TARGETCONNECTIONPROFILE_FILES}
...                                                                 target-conn-profile-gnmi.yaml
...                                                                 target-conn-profile-netconf.yaml
...                                                                 target-conn-profile-noop.yaml
${SDCIO_INTEGRATION_TESTS_TARGETCONNECTIONPROFILE_FILES_BASE}       ${CURDIR}/01-crs/connection-profiles
@{SDCIO_INTEGRATION_TESTS_TARGETCONNECTIONPROFILE_FILES}
...                                                                 conn_profile_sros_netconf.yaml
...                                                                 conn_profile_sros_gnmi.yaml
...                                                                 conn_profile_srl_gnmi.yaml

# TargetSyncProfiles
${SDCIO_CONFIG_SERVER_TARGETSYNCPROFILE_FILES_BASE}                 ${SDCIO_CONFIG_SERVER_REPO_PATH}/example/sync-profiles
@{SDCIO_CONFIG_SERVER_TARGETSYNCPROFILE_FILES}
...                                                                 target-sync-profile-netconf.yaml
...                                                                 target-sync-profile-gnmi.yaml
...                                                                 target-sync-profile-gnmi-once-and-onchange.yaml
${SDCIO_INTEGRATION_TESTS_TARGETSYNCPROFILE_FILES_BASE}             ${CURDIR}/01-crs/sync-profiles
@{SDCIO_INTEGRATION_TESTS_TARGETSYNCPROFILE_FILES}
...                                                                 sync_profile_sros_netconf.yaml
...                                                                 sync_profile_sros_gnmi.yaml
...                                                                 sync_profile_srl_gnmi.yaml

# DiscoveryVendorProfiles
${SDCIO_CONFIG_SERVER_DISCOVERYVENDORPROFILE_FILES_BASE}	${SDCIO_CONFIG_SERVER_REPO_PATH}/example/discoveryvendor-profile
@{SDCIO_CONFIG_SERVER_DISCOVERYVENDORPROFILE_FILES}
...								discoveryvendor-profile-arista.yaml
...								discoveryvendor-profile-nokia-srlinux.yaml
...								discoveryvendor-profile-nokia-sros.yaml
${SDCIO_INTEGRATION_TESTS_DISCOVERVENDORPROFILE_FILES_BASE}	${CURDIR}/01-crs/discovery-vendor-profile
@{SDCIO_INTEGRATION_TESTS_DISCOVERVENDORPROFILE_FILES}
...								discoveryvendor-profile-arista-eos.yaml
...								discoveryvendor-profile-nokia-srlinux.yaml
...								discoveryvendor-profile-nokia-sros.yaml

# DiscoveryRules
${SDCIO_CONFIG_SERVER_DISCOVERYRULE_FILES_BASE}                     ${SDCIO_CONFIG_SERVER_REPO_PATH}/example/discovery-rule
@{SDCIO_CONFIG_SERVER_DISCOVERYRULE_FILES}
...                                                                 discovery_address.yaml
...                                                                 discovery_prefix.yaml
...                                                                 nodiscovery.yaml
${SDCIO_INTEGRATION_TESTS_DISCOVERYRULE_FILES_BASE}                 ${CURDIR}/01-crs/discovery-rule
@{SDCIO_INTEGRATION_TESTS_DISCOVERYRULE_FILES}
...                                                                 discovery_sros_netconf_address.yaml
...                                                                 discovery_sros_gnmi_prefix.yaml
...                                                                 discovery_srl_gnmi_prefix.yaml

### CURRENTLY USED BY 02-CRUD.
${sr1}                                                              172.21.1.11
${sr2}                                                              172.21.1.12
${SROS_USERNAME}                                                    admin
${SROS_PASSWORD}                                                    NokiaSros1!
${srl1}                                                             172.21.0.11
${srl2}                                                             172.21.0.12
${srl3}                                                             172.21.0.13
${SRL_USERNAME}                                                     admin
${SRL_PASSWORD}                                                     NokiaSrl1!
