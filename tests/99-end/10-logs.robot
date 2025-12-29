*** Settings ***

Resource            ../variables.robot
Resource    ../Keywords/config-server.robot

*** Test Cases ***

Collect container logs
    Collect Pod Logs By Label    namespace=${SDCIO_SYSTEM_NAMESPACE}    log_dir=./integration-tests/tests/out/logs


   