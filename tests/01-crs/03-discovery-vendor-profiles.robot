*** Settings ***
Library     Collections
Resource    ../variables.robot
Resource    ../Keywords/yq.robot
Resource    ../Keywords/k8s/kubectl.robot


*** Test Cases ***
Install DISCOVERYRULEs
    [Documentation]    Installs the SDCIO_INTEGRATION_TESTS_DISCOVERVENDORPROFILE_FILES defined in the variables.robot file. After prepending the SDCIO_DISCOVERYRULE_FILES_BASE

    @{SDCIO_DISCOVERYVENDORPROFILE_FILES_ABSOLUTE}=    Create List

    FOR    ${s}    IN    @{SDCIO_INTEGRATION_TESTS_DISCOVERVENDORPROFILE_FILES}
        Append To List
        ...    ${SDCIO_DISCOVERYVENDORPROFILE_FILES_ABSOLUTE}
        ...    ${SDCIO_INTEGRATION_TESTS_DISCOVERVENDORPROFILE_FILES_BASE}/${s}
    END

    # Install the schemas
    FOR    ${s}    IN    @{SDCIO_DISCOVERYVENDORPROFILE_FILES_ABSOLUTE}
        ${rc}    ${output}=    kubectl apply    ${s}
    END

    # export the variable
    Set Suite Variable    ${SDCIO_DISCOVERYVENDORPROFILE_FILES_ABSOLUTE}
