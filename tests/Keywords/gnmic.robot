*** Settings ***
Resource    k8s/kubectl.robot
Library     RPA.JSON


*** Keywords ***

Get Config from node
    [Documentation]    Retrieve Config from a node, through collecting a gNMI path
    [Arguments]    ${node}    ${options}    ${username}    ${password}    ${path}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 ${options} -u ${username} -p ${password} get --type CONFIG --path ${path}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${json} =    Convert string to JSON    ${output}
    ${values} =    Get values from JSON    ${json}    $.[*].updates.[*]
    RETURN    ${rc}    ${values}

Delete Config from node
    [Documentation]    Delete Config from a node, through collecting a gNMI path
    [Arguments]    ${node}    ${options}    ${username}    ${password}    ${path}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 ${options} -u ${username} -p ${password} set --delete --path ${path}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${json} =    Convert string to JSON    ${output}
    ${values} =    Get values from JSON    ${json}    $.[*].updates.[*]
    RETURN    ${rc}    ${values}
