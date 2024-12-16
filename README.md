# SDCIO Integration Tests

This repo contains the integration tests we perform. The goal here is we try and setup a minimal k8s cluster (kind) and install SDCIO with it's dependencies.

As we're verifying the end-to-end flow, containerlab is used to spin up a lab of nodes, which are reachable through netconf/gNMI. 

Depending on the version that requires installation in the CI/CD pipeline, we update (the input vars)[./artifacts/kform/configmap-input-vars.yaml.tmpl]

Finally we run the robot testing framework to create Config snippets/Intents and verify our components end-to-end. 
