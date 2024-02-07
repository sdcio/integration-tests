*** Variables ***
${CERT_MANAGER_VERSION}            %{CERT_MANAGER_VERSION=v1.14.1}
${SDCIO_NAMESPACE}                 network-system
${SDCIO_COLOCATED_DEPLOYMENT}      config-server
@{SDCIO_APIServices}               v1alpha1.config.sdcio.dev    v1alpha1.inv.sdcio.dev