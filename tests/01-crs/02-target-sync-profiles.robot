*** Settings ***
Library             Collections
Resource            ../variables.robot
Resource            ../Keywords/yq.robot
Resource            ../Keywords/k8s/kubectl.robot


*** Test Cases ***
Install TargetSYNCProfiles
    [Documentation]    Installs the SDCIO_TARGETSYNCPROFILE_FILES defined in the variables.robot file. After prepending the SDCIO_TARGETSYNCPROFILE_FILES_BASE

    @{SDCIO_TARGETSYNCPROFILE_FILES_ABSOLUTE}=    Create List

    # Build the full paths for install and later checks
    FOR    ${s}    IN     @{SDCIO_TARGETSYNCPROFILE_FILES}
        Append To List    ${SDCIO_TARGETSYNCPROFILE_FILES_ABSOLUTE}     ${SDCIO_CONFIG_SERVER_REPO_PATH}/${SDCIO_TARGETSYNCPROFILE_FILES_BASE}/${s}
    END

    # Install the TARGETSYNCPROFILE
    FOR    ${s}    IN     @{SDCIO_TARGETSYNCPROFILE_FILES_ABSOLUTE}
        ${rc}    ${output} =    kubectl apply    ${s}
    END

    # export the variable
    Set Suite Variable    ${SDCIO_TARGETSYNCPROFILE_FILES_ABSOLUTE}  
