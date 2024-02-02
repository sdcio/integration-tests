*** Settings ***
Documentation     The Library relies on the following variables being available on execution
...               DATA-SERVER-IP: IP of data server
...               DATA-SERVER-PORT: TCP port of data server
...               SCHEMA-SERVER-IP: IP of schema server
...               SCHEMA-SERVER-PORT: TCP port of schema server
...               CACHE-SERVER-IP: IP of schema server
...               CACHE-SERVER-PORT: TCP port of schema server
Library           String
Library           Process
Library           Collections
Library           OperatingSystem
Resource          ../../resources.robot


*** Keywords ***
DSCreateCandidate
    [Documentation]    Create a new named Candidate in the given Datastore
    [Arguments]    ${datastore}    ${candidate}
    ${result} =    Run Process    ${DATA-CLIENT-BIN}     -a    ${DATA-SERVER-IP}:${DATA-SERVER-PORT}    datastore    create    --ds    ${datastore}    --candidate    ${candidate}
    RETURN    ${result}

DSDeleteCandidate
    [Documentation]    Delete a named Candidate in the given Datastore
    [Arguments]    ${datastore}    ${candidate}
    ${result} =    Run Process    ${DATA-CLIENT-BIN}     -a    ${DATA-SERVER-IP}:${DATA-SERVER-PORT}    datastore    delete    --ds    ${datastore}    --candidate    ${candidate}
    RETURN    ${result}

DSCommit
    [Documentation]    Performs a commit on the given datastore/candidate and returns the Process Result object https://robotframework.org/robotframework/latest/libraries/Process.html#Result%20object
    [Arguments]    ${datastore}    ${candidate}
    ${result} =    Run Process    ${DATA-CLIENT-BIN}     -a    ${DATA-SERVER-IP}:${DATA-SERVER-PORT}    datastore    commit    --ds    ${datastore}    --candidate    ${candidate}
    RETURN    ${result}

DSSet
    [Documentation]    Applies to the candidate of the given datastore the provided update
    [Arguments]    ${datastore}    ${candidate}    ${update}
    ${result} =    Run Process    ${DATA-CLIENT-BIN}     -a    ${DATA-SERVER-IP}:${DATA-SERVER-PORT}    data    set    --ds    ${datastore}    --candidate    ${candidate}    --update    ${update}
    Log    ${result.stdout}
    Log    ${result.stderr}
    RETURN    ${result}

DSGetDatastore
    [Documentation]   Performa get on the given Datastore
    [Arguments]    ${datastore}
    ${result} =    Run Process    ${DATA-CLIENT-BIN}     -a    ${DATA-SERVER-IP}:${DATA-SERVER-PORT}    datastore    get    --ds    ${datastore}
    RETURN    ${result}

## SchemaCtl
SSGetSchema
    [Documentation]    Retrieve the schema element described by name (plattform name), version and vendor under the given path.
    [Arguments]    ${name}    ${version}    ${vendor}    ${path}
    ${result} =    Run Process    ${SCHEMA-CLIENT-BIN}    -a    ${SCHEMA-SERVER-IP}:${SCHEMA-SERVER-PORT}    schema    get    --name    ${name}    --version    ${version}    --vendor    ${vendor}    --path    ${path}    
    RETURN    ${result}

SSList
    [Documentation]    Retrieve a list of all available schemas.
    ${result} =    Run Process    ${SCHEMA-CLIENT-BIN}    -a    ${SCHEMA-SERVER-IP}:${SCHEMA-SERVER-PORT}    schema    list
    RETURN    ${result}

SSTo-Path
    [Documentation]    Convert a list of path elements and key values to a valid path
    [Arguments]    ${name}    ${version}    ${vendor}    ${path}
    ${result} =    Run Process    ${SCHEMA-CLIENT-BIN}    -a    ${SCHEMA-SERVER-IP}:${SCHEMA-SERVER-PORT}    schema     to-path     --name ${name}     --version    ${version}    --vendor    ${vendor}    --cp     ${path}
    RETURN    ${result}

SSExpand
    [Documentation]    Retrieve all sub paths for the given path. Format can either be ${EMPTY} or "xpath"
    [Arguments]    ${name}    ${version}    ${vendor}    ${path}    ${format}

     @{params} =    Create List     ${SCHEMA-CLIENT-BIN}    -a    ${SCHEMA-SERVER-IP}:${SCHEMA-SERVER-PORT}    schema     expand    --name    ${name}    --version    ${version}    --vendor    ${vendor}    --path    ${path}
    IF    "${format}" == "xpath"
        Append To List    ${params}    --xpath
    END

    ${result} =    Run Process     @{params}
    RETURN    ${result}

## CacheCtl
CSClone
    [Documentation]    Clone a datastore in the cache
    [Arguments]    ${name}    ${newname}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    clone    --name    ${name}    --clone    ${newname}
    RETURN    ${result}

CSCreate
    [Documentation]    Create a datastore in the cache
    [Arguments]    ${name}    ${cached}    ${ephemeral}
    
    @{params} =    Create List     ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    create    --name    ${name}
    IF    "${cached}" == "${True}"
        Append To List    ${params}    --cached
    END
    IF    "${ephemeral}" == "${True}"
        Append To List  ${params}    --ephemeral
    END

    ${result} =    Run Process        @{params}
    RETURN    ${result}

CSCreateCandidate
    [Documentation]    Create a candidate from a cache instance
    [Arguments]    ${name}    ${candidate}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    create-candidate    --name    ${name}    --candidate    ${candidate}
    RETURN    ${result}

CSDelete
    [Documentation]    delete a cache instance
    [Arguments]    ${name}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    delete    --name    ${name}
    RETURN    ${result}

CSExists
    [Documentation]    check if a cache instance exists
    [Arguments]    ${name}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    exists    --name    ${name}
    RETURN    ${result}

CSGetChanges
    [Documentation]    get changes made to a candidate
    [Arguments]    ${name}    ${candidate}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    get-changes    --name    ${name}    --candidate    ${candidate}
    RETURN    ${result}

CSGet
    [Documentation]    get a cache instance details
    [Arguments]    ${name}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    get    --name    ${name}
    RETURN    ${result}

CSRead
    [Documentation]    get a cache instance details
    [Arguments]    ${name}    ${candidate}    ${path}    ${format}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    read    --name    ${name}/${candidate}    --path    ${path}    --format    ${format}
    RETURN    ${result}

CSModifyDelete
    [Documentation]    delete modify values in the cache
    [Arguments]    ${name}    ${candidate}    ${deletePath}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    modify    --name    ${name}/${candidate}    --delete    ${deletePath}
    RETURN    ${result}

CSModifyUpdate
    [Documentation]    update modify values in the cache
    [Arguments]    ${name}    ${candidate}    ${updateData}
    ${result} =    Run Process    ${CACHE-CLIENT-BIN}    -a    ${CACHE-SERVER-IP}:${CACHE-SERVER-PORT}    modify    --name    ${name}/${candidate}    --update    ${updateData}
    RETURN    ${result}


# Helper
ExtractResponse
    [Documentation]    Takes the output of the client binary and returns just the response part, stripping the request
    [Arguments]    ${output}
    @{split} =	Split String	${output}    response:
    RETURN    ${split}[1]

LogMustStatements
    [Documentation]    Takes vendor, name, version and a path, retrieves the schema for the given path, extracts the returned must_statements and logs them.
    [Arguments]    ${name}    ${version}    ${vendor}    ${path}
    ${schema} =     SSGetSchema     ${name}    ${version}    ${vendor}    ${path}
    ${msts} =    _ExtractMustStatements    ${schema.stdout}
    FOR    ${item}    IN    @{msts}
        Log    ${item}
    END

LogLeafRefStatements
    [Documentation]    Takes vendor, name, version and a path, retrieves the schema for the given path, extracts the returned leafref_statements and logs them.
    [Arguments]    ${name}    ${version}    ${vendor}    ${path}
    ${schema} =     SSGetSchema     ${name}    ${version}    ${vendor}    ${path}
    ${lref} =    _ExtractLeafRefStatements    ${schema.stdout}
    FOR    ${item}    IN    @{lref}
        Log    ${item}
    END

_ExtractMustStatements
    [Documentation]    Takes a GetSchema response and extracts the must_statements of the response. Returns an array with all the must_statements as a string array.
    [Arguments]    ${input}
    ${matches} =	Get Regexp Matches	${input}    must_statements:\\s*\{[\\s\\S]*?\}    flags=MULTILINE | IGNORECASE
    RETURN    ${matches}

_ExtractLeafRefStatements
    [Documentation]    Takes a GetSchema response and extracts the leafref_statements of the response.
    [Arguments]    ${input}
    ${matches} =	Get Regexp Matches	${input}    leafref:\\s*".*"    flags=IGNORECASE
    RETURN    ${matches}