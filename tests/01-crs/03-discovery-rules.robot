*** Settings ***
Library     Collections
Resource    ../variables.robot
Resource    ../Keywords/yq.robot
Resource    ../Keywords/k8s/kubectl.robot


*** Test Cases ***
Install DISCOVERYRULEs
    [Documentation]    Installs the SDCIO_SCHEMA_FILES defined in the variables.robot file. After prepending the SDCIO_DISCOVERYRULE_FILES_BASE

    @{SDCIO_DISCOVERYRULE_FILES_ABSOLUTE}=    Create List

    # Build the full paths for install and later checks
    # for loop is sourced from the config-server repository.
    # FOR    ${s}    IN    @{SDCIO_CONFIG_SERVER_DISCOVERYRULE_FILES}
    #    Append To List
    #    ...    ${SDCIO_DISCOVERYRULE_FILES_ABSOLUTE}
    #    ...    ${SDCIO_CONFIG_SERVER_DISCOVERYRULE_FILES_BASE}/${s}
    # END
    # for loop is sourced from this repository.
    FOR    ${s}    IN    @{SDCIO_INTEGRATION_TESTS_DISCOVERYRULE_FILES}
        Append To List
        ...    ${SDCIO_DISCOVERYRULE_FILES_ABSOLUTE}
        ...    ${SDCIO_INTEGRATION_TESTS_DISCOVERYRULE_FILES_BASE}/${s}
    END

    # Install the schemas
    FOR    ${s}    IN    @{SDCIO_DISCOVERYRULE_FILES_ABSOLUTE}
        ${rc}    ${output}=    kubectl apply    ${s}
    END

    # export the variable
    Set Suite Variable    ${SDCIO_DISCOVERYRULE_FILES_ABSOLUTE}
