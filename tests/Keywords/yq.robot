*** Settings ***
Library             OperatingSystem

*** Keywords ***
YQ file
    [Documentation]    Extract a certain field from a json file
    [Arguments]    ${file}    ${expression}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    yq ${expression} ${file}
    Log    ${output}
    [Return]    ${rc}    ${output}

YQ extract metadata.name from file
    [Documentation]     Takes a krm yaml file and returns the metadata.name attribute
    [Arguments]    ${file}
    ${rc}    ${output} =    YQ file    ${file}    '.metadata.name'
    Log    ${output}
    [Return]    ${output}

YQ extract metadata.namespace from file
    [Documentation]     Takes a krm yaml file and returns the metadata.namespace attribute
    [Arguments]    ${file}
    ${rc}    ${output} =    YQ file    ${file}    '.metadata.namespace'
    [Return]    ${output}