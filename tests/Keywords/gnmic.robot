*** Settings ***
Resource    k8s/kubectl.robot
Resource    jq.robot
Library     RPA.JSON


*** Keywords ***

Get Config from node
    [Documentation]    Retrieve Config from a node, through collecting a gNMI path
    [Arguments]    ${node}    ${options}    ${username}    ${password}    ${path}    ${filter}=None
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 ${options} -u ${username} -p ${password} get --type CONFIG --path ${path}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${json} =    Convert string to JSON    ${output}
    IF ${filter} IS DEFINED
        ${values} =    Get values from JSON    ${json}    $.[*].updates.[*].values.${filter}
    ELSE
        ${values} =    Get values from JSON    ${json}    $.[*].updates.[*].values
    END
    RETURN    ${rc}    ${values}

Get Config from node and Verify Intent
    [Documentation]    Retrieve Config from a SRLinux node, through collecting a gNMI path and compare against expectedoutput
    [Arguments]    ${node}    ${options}    ${username}    ${password}    ${path}    ${filter}=None    ${expectedoutput}
    ${output} =    Get Config from node
    ...    ${node}
    ...    ${options}
    ...    ${username}
    ...    ${password}
    ...    ${path}
    ...    ${filter}
    
    ${compare} =        JQ Compare JSON	${output}    ${expectedoutput}
    Should Be True      ${compare}
    RETURN    ${compare}

Delete Config from node
    [Documentation]    Delete Config from a node, through collecting a gNMI path
    [Arguments]    ${node}    ${options}    ${username}    ${password}    ${path}
    ${rc}    ${output} =    Run And Return Rc And Output
    ...    gnmic -a ${${node}} -p 57400 ${options} -u ${username} -p ${password} set --delete ${path}
    Log    ${output}
    Should Be Equal As Integers    ${rc}    0
    ${json} =    Convert string to JSON    ${output}
    ${values} =    Get values from JSON    ${json}    $.[*].updates.[*]
    RETURN    ${rc}    ${values}