*** Settings ***
Library     Collections
Resource    ../variables.robot
Resource    ../Keywords/k8s/kubectl.robot


*** Test Cases ***
Install Secrets
    [Documentation]    Installs the Secrets defined in the variables.robot file. After prepending the SDCIO_SECRETS_FILES_BASE

    @{SDCIO_SECRETS_FILES_ABSOLUTE}=    Create List

    # Build the full paths for install and later checks
    # for loop is sourced from the config-server repository.
    # FOR    ${s}    IN    @{SDCIO_CONFIG_SERVER_SECRETS_FILES}
    #    Append To List
    #    ...    ${SDCIO_SECRETS_FILES_ABSOLUTE}
    #    ...    ${SDCIO_CONFIG_SERVER_SECRETS_FILES_BASE}/${s}
    # END
    # for loop is sourced from this repository.
    FOR    ${s}    IN    @{SDCIO_INTEGRATION_TESTS_SECRETS_FILES}
        Append To List
        ...    ${SDCIO_SECRETS_FILES_ABSOLUTE}
        ...    ${SDCIO_INTEGRATION_TESTS_SECRETS_FILES_BASE}/${s}
    END

    # Install the SECRETS
    FOR    ${s}    IN    @{SDCIO_SECRETS_FILES_ABSOLUTE}
        ${rc}    ${output}=    kubectl apply    ${s}
    END

    # export the variable
    Set Suite Variable    ${SDCIO_SECRETS_FILES_ABSOLUTE}
