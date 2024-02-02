*** Settings ***
Resource          ../../keywords/server.robot
Resource          ../../keywords/ctl.robot
Library           OperatingSystem
Library           String
Library           Process
Resource          ../../../resources.robot
Suite Setup       SetupCache    ${False}    ${cache-server-config}    ${cache-server-process-alias}    ${cache-server-stderr}
Suite Teardown    Teardown

*** Variables ***
${cache-server-config}    ./tests/robot/tests/cache/cache.yaml

${CACHE-SERVER-IP}    127.0.0.1
${CACHE-SERVER-PORT}    50100

# internal vars
${cache-server-process-alias}    csa
${cache-server-stderr}    /tmp/cs-out

${cache01Name}    CacheInstance01
${cache02Name}    CacheInstance02
${cache03Name}    CacheInstance03
${candidate01}    Candidate01
${candidate02}    Candidate02
${candidate03}    Candidate03

${cacheDir}    /tmp/caches

*** Test Cases ***
Check Server State
     CheckCacheServerState    ${cache-server-process-alias}

Create, Get and Delete Cache
    ${result} =    CSExists    ${cache01Name}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    false
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSCreate    ${cache01Name}    ${False}    ${False}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSExists    ${cache01Name}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    true
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSGet    ${cache01Name}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    ${cache01Name}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSDelete    ${cache01Name}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    [Teardown]    CSDelete    ${cache01Name}

Create Cache, Create Candidate and Delete Cache 
    ${result} =    CSCreate    ${cache01Name}    ${False}    ${False}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSCreateCandidate    ${cache01Name}    ${candidate01}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSGet    ${cache01Name}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    ${candidate01}
    Should Contain    ${result.stdout}    ${cache01Name}
    Should Be Equal As Integers    ${result.rc}    0

    [Teardown]    CSDelete    ${cache01Name}

Create Cache, Create Multiple Candidate and Delete Cache 
    ${result} =    CSCreate    ${cache01Name}    ${False}    ${False}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSCreateCandidate    ${cache01Name}    ${candidate01}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSCreateCandidate    ${cache01Name}    ${candidate02}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSCreateCandidate    ${cache01Name}    ${candidate03}
    Log    ${result.stdout}
    Log    ${result.stderr}

    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSGet    ${cache01Name}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    ${cache01Name}
    Should Contain    ${result.stdout}    ${candidate01}
    Should Contain    ${result.stdout}    ${candidate02}
    Should Contain    ${result.stdout}    ${candidate03}
    Should Be Equal As Integers    ${result.rc}    0

    [Teardown]    CSDelete    ${cache01Name}

Create Cache, Create Candidate, Modify Candidate and Delete Cache 
    ${result} =    CSCreate    ${cache01Name}    ${False}    ${False}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSCreateCandidate    ${cache01Name}    ${candidate01}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSModifyUpdate    ${cache01Name}    ${candidate01}    a,b,c:::string:::this is the set value
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Not Contain    ${result.stderr}    error
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSGetChanges    ${cache01Name}    ${candidate01}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    this is the set value
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSRead    ${cache01Name}    ${candidate01}    a,b,c     flat
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    a/b/c
    Should Contain    ${result.stdout}    this is the set value
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    CSRead    ${cache01Name}    ${candidate01}    a,b,c     json
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    "value": "ChV0aGlzIGlzIHRoZSBzZXQgdmFsdWU=" 
    Should Be Equal As Integers    ${result.rc}    0

    [Teardown]    CSDelete    ${cache01Name}

