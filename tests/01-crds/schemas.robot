*** Settings ***
Library             OperatingSystem
Library             Process
Resource            ../variables.robot
Resource            ../Keywords/schemas.robot
Resource    ../Keywords/yq.robot


*** Test Cases ***
Install Schemas
    [Documentation]    Installs the SDCIO_SCHEMA_FILES defined in the variables.robot file. After prepending the SDCIO_SCHEMA_FILES_BASE
    FOR    ${s}    IN     @{SDCIO_SCHEMA_FILES}
        Install Schema    ${SDCIO_SCHEMA_FILES_BASE}/${s}
    END

Wait for Schemas ready
    Wait Until Keyword Succeeds    2 min    2s    Check Schemas ready
    

*** Keywords ***
Install Schema
    [Arguments]    ${file}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    kubectl apply -f ${file}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0

Check Schemas ready
    FOR    ${s}    IN     @{SDCIO_SCHEMA_FILES}
        ${resource} =     YQ extract metadata.name from file    ${SDCIO_SCHEMA_FILES_BASE}/${s}
        Log    ${resource}
        Schemas Check Loaded    ${SDCIO_RESOURCE_NAMESPACE}    ${resource}
    END