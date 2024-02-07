*** Variables ***
${CERT_MANAGER_VERSION}            %{CERT_MANAGER_VERSION=v1.14.1}
${SDCIO_SYSTEM_NAMESPACE}          network-system
${SDCIO_RESOURCE_NAMESPACE}        default
${SDCIO_COLOCATED_DEPLOYMENT}      config-server
@{SDCIO_APIServices}               v1alpha1.config.sdcio.dev    v1alpha1.inv.sdcio.dev
${SDCIO_SCHEMA_FILES_BASE}         %{SDCIO_SCHEMA_FILES_BASE=config-server/example/schemas}
@{SDCIO_SCHEMA_FILES}              schema-nokia-sros-23.10.yaml    schema-nokia-srl-23.10.1.yaml

${sr1}               172.21.1.11
${sr2}               172.21.1.12
${SROS_USERNAME}     admin
${SROS_PASSWORD}     admin