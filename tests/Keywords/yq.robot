*** Settings ***
Library     OperatingSystem


*** Keywords ***
YQ file
    [Documentation]    Extract a certain field from a json file
    [Arguments]    ${file}    ${expression}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    yq ${expression} ${file}
    Log    ${output}
    RETURN    ${rc}    ${output}

YQ extract metadata.name from file
    [Documentation]    Takes a krm yaml file and returns the metadata.name attribute
    [Arguments]    ${file}
    ${rc}    ${output} =    YQ file    ${file}    '.metadata.name'
    Log    ${output}
    RETURN    ${output}

YQ extract metadata.namespace from file
    [Documentation]    Takes a krm yaml file and returns the metadata.namespace attribute
    [Arguments]    ${file}
    ${rc}    ${output} =    YQ file    ${file}    '.metadata.namespace'
    RETURN    ${output}
