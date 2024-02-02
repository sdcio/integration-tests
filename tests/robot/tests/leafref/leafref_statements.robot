*** Settings ***
Resource          ../../keywords/server.robot
Resource          ../../keywords/ctl.robot
Library           OperatingSystem
Library           String
Library           Process
Resource          ../../../resources.robot
Suite Setup       Setup    ${False}    ${schema-server-config}    ${schema-server-process-alias}    ${schema-server-stderr}    ${data-server-config}    ${data-server-process-alias}    ${data-server-stderr}    ${cache-server-config}    ${cache-server-process-alias}    ${cache-server-stderr}
Suite Teardown    Teardown

*** Variables ***
${schema-server-config}    ./tests/robot/tests/must/schema-server.yaml
${data-server-config}    ./tests/robot/tests/must/data-server.yaml
${cache-server-config}    ./tests/robot/tests/must/cache.yaml
${schema-server-ip}    127.0.0.1
${schema-server-port}    55000
${data-server-ip}    127.0.0.1
${data-server-port}    56000

# TARGET
${srlinux1-name}    srl1
${srlinux1-candidate}    default
${srlinux1-schema-name}    srl
${srlinux1-schema-version}    22.11.2
${srlinux1-schema-Vendor}    Nokia


# internal vars
${schema-server-process-alias}    ssa
${schema-server-stderr}    /tmp/ss-out
${data-server-process-alias}    dsa
${data-server-stderr}    /tmp/ds-out
${cache-server-process-alias}    csa
${cache-server-stderr}    /tmp/cs-out


*** Test Cases ***
Check Server State
     CheckServerState    ${schema-server-process-alias}    ${data-server-process-alias}    ${cache-server-process-alias}

BGP export-policy non-existing
    LogLeafRefStatements    ${srlinux1-schema-name}    ${srlinux1-schema-version}    ${srlinux1-schema-vendor}    network-instance[name=default]/protocols/bgp/group

    DSCreateCandidate    ${srlinux1-name}    ${srlinux1-candidate}

    ${result} =    DSSet    ${srlinux1-name}    ${srlinux1-candidate}    network-instance[name=default]/protocols/bgp/group[group-name=foo]/export-policy:::bar-policy
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    DSCommit    ${srlinux1-name}    ${srlinux1-candidate}
    Log    ${result.stderr}
    Should Contain    ${result.stderr}    missing leaf reference
    Should Be Equal As Integers    ${result.rc}    1

    DSDeleteCandidate    ${srlinux1-name}    ${srlinux1-candidate}

BGP export-policy existing
    LogLeafRefStatements    ${srlinux1-schema-name}    ${srlinux1-schema-version}    ${srlinux1-schema-vendor}    network-instance[name=default]/protocols/bgp/group

    DSCreateCandidate    ${srlinux1-name}    ${srlinux1-candidate}

    ${result} =    SSGetSchema    ${srlinux1-schema-name}    ${srlinux1-schema-version}    ${srlinux1-schema-vendor}    routing-policy/policy[name=bar-policy]/default-action/policy-result:::reject
    Log    ${result.stdout}
    Log    ${result.stderr}

    ${result} =    DSSet    ${srlinux1-name}    ${srlinux1-candidate}    routing-policy/policy[name=mypolicy]/default-action/policy-result:::reject
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    DSSet    ${srlinux1-name}    ${srlinux1-candidate}    network-instance[name=default]/protocols/bgp/group[group-name=foo]/export-policy:::mypolicy
    Should Be Equal As Integers    ${result.rc}    0

    ${result} =    DSCommit    ${srlinux1-name}    ${srlinux1-candidate}
    Log    ${result.stderr}
    Should Be Equal As Integers    ${result.rc}    0

    DSDeleteCandidate    ${srlinux1-name}    ${srlinux1-candidate}
