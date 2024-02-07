*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/schemas.robot
Resource            ../Keywords/yq.robot


*** Test Cases ***
Install Schemas
    [Documentation]    Installs the SDCIO_SCHEMA_FILES defined in the variables.robot file. After prepending the SDCIO_SCHEMA_FILES_BASE
    FOR    ${s}    IN     @{SDCIO_SCHEMA_FILES}
        Install Schema    ${SDCIO_CONFIG_SERVER_REPO_PATH}/${SDCIO_SCHEMA_FILES_BASE}/${s}
    END

Wait for Schemas to become ready
    Wait Until Keyword Succeeds    15min    5s    Check Schemas ready
    

*** Keywords ***
Install Schema
    [Documentation]    Installs a single Schema File
    [Arguments]    ${file}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${file}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Check Schemas ready
    [Documentation]    Iterates through the SDCIO_SCHEMA_FILES, extracts the .metadata.name and checks makes sure schemas are ready
    FOR    ${s}    IN     @{SDCIO_SCHEMA_FILES}
        ${resource} =     YQ extract metadata.name from file    ${SDCIO_CONFIG_SERVER_REPO_PATH}/${SDCIO_SCHEMA_FILES_BASE}/${s}
        Log    ${resource}
        Schemas Check Loaded    ${SDCIO_RESOURCE_NAMESPACE}    ${resource}
    END