# SDC Integration Tests

![sdc logo](https://docs.sdcio.dev/assets/logos/SDC-transparent-withname-100x133.png)

This repo contains the integration tests for Schema Driven Configuration (SDC). The goal here is we try and setup a
minimal k8s cluster (kind) and install SDC with it's dependencies.

As we're verifying the end-to-end flow, containerlab is used to spin up a lab of nodes, which are reachable through
netconf/gNMI. 

Depending on the version that requires installation in the CI/CD pipeline, we update
(the input vars)[./artifacts/kform/configmap-input-vars.yaml.tmpl]

Finally we run the robot testing framework to create Config snippets/Intents and verify our components end-to-end. 

## Join us

Have questions, ideas, bug reports or just want to chat? Come join [our discord server](https://discord.com/channels/1240272304294985800/1311031796372344894).

## License and Code of Conduct

Code is under the [Apache License 2.0](LICENSE), documentation is [CC BY 4.0](LICENSE-documentation).

The SDC project is following the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md).
More information and links about the CNCF Code of Conduct are [here](code-of-conduct.md).
