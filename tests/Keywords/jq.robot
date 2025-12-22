*** Settings ***
Library     OperatingSystem

*** Keywords ***
JQ Compare JSON
    [Documentation]    Compares two JSON objects using jq
    [Arguments]    ${j1}    ${j2}
    ${json1} =   Convert JSON to string    ${j1}
    ${json2} =   Convert JSON to string    ${j2}
    Log	${json1}
    Log	${json2}
    ${output} =    Run
    ...    jq -n --argjson j1 '${json1}' --argjson j2 '${json2}' '( $j1 | to_entries | sort_by(.key) ) == ( $j2 | to_entries | sort_by(.key) )'
    ${return} =	Convert To Boolean	${output}
    RETURN    ${return}
