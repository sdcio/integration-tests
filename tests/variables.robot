*** Variables ***
${CERT_MANAGER_VERSION}            %{CERT_MANAGER_VERSION=v1.14.1}
${SDCIO_SYSTEM_NAMESPACE}          network-system
${SDCIO_RESOURCE_NAMESPACE}        default
${SDCIO_COLOCATED_DEPLOYMENT}      config-server
@{SDCIO_APIServices}               v1alpha1.config.sdcio.dev    v1alpha1.inv.sdcio.dev
${SDCIO_CONFIG_SERVER_REPO_PATH}   ./config-server

# Schemas
${SDCIO_SCHEMA_FILES_BASE}         %{SDCIO_SCHEMA_FILES_BASE=example/schemas}
@{SDCIO_SCHEMA_FILES}              schema-nokia-sros-23.10.yaml    schema-nokia-srl-23.10.1.yaml

# TargetConnectionProfiles
${SDCIO_TARGETCONNECTIONPROFILE_FILES_BASE}    %{SDCIO_TARGETCONNECTIONPROFILE_FILES_BASE=example/connection-profiles}
@{SDCIO_TARGETCONNECTIONPROFILE_FILES}              target-conn-profile-gnmi.yaml    target-conn-profile-netconf.yaml    target-conn-profile-noop.yaml

# TargetSyncProfiles
${SDCIO_TARGETSYNCPROFILE_FILES_BASE}    %{SDCIO_TARGETSYNCPROFILE_FILES_BASE=example/sync-profiles}
@{SDCIO_TARGETSYNCPROFILE_FILES}              target-sync-profile-netconf.yaml    target-sync-profile-gnmi.yaml    target-sync-profile-gnmi-once-and-onchange.yaml

# DiscoveryRules
${SDCIO_DISCOVERYRULE_FILES_BASE}    %{SDCIO_DISCOVERYRULE_FILES_BASE=example/discovery-rule}
@{SDCIO_DISCOVERYRULE_FILES}              discovery_address.yaml    discovery_prefix.yaml    nodiscovery.yaml

${sr1}               172.21.1.11
${sr2}               172.21.1.12
${SROS_USERNAME}     admin
${SROS_PASSWORD}     admin
