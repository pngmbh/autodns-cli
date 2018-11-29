#!/usr/bin/env bash

#set -euxo pipefail

source ./.autodns-cli.rc
source ./func.sh
source ./assert.sh

prog=autodns-cli.test

declare -r endpoint=http://example.org

AUTODNS_CONTEXT=1
AUTODNS_USER=foo
AUTODNS_PASSWORD=bar
MY_ZONE=example.org

_test_build_call(){
    local resp=`_build_call "$1"`

    assert_eq "$2" "$resp"
    if [ "$?" == 0 ]; then
        log_success "_build_call works!"
    else
        log_failure "_build_call failed!"

        echo "Expected: $2"
        echo "Got:      $resp"
    fi
}

test_build_call(){
    local expected_1="curl --silent --show-error --user-agent $prog -H X-Domainrobot-Context:1 -X POST -H Accept:application/json -H Content-Type:application/json -u foo:bar http://example.org"
    _test_build_call "POST" "$expected_1"

    local expected_2="curl --silent --show-error --user-agent $prog -H X-Domainrobot-Context:1 -X PUT -H Accept:application/json -H Content-Type:application/json -u foo:bar http://example.org"
    _test_build_call "PUT" "$expected_2"

    local expected_3="curl --silent --show-error --user-agent $prog -H X-Domainrobot-Context:1 -X GET -H Accept:application/json -u foo:bar http://example.org"
    _test_build_call "GET" "$expected_3"
}

_test_create_record(){
    local test_record=`_create_record "$1"`
    assert_eq "$test_record" "foo"
    if [ "$?" == 0 ]; then
        log_success "_create_record works!"
    else
        log_failure "_create_record failed!"
    fi
}

test_create_record(){
    _test_create_record "foo.example.org"
    _test_create_record "foo"
}

_test_has_records(){
    _has_records "$1"
    local resp=$?

    assert_eq $resp $2
    if [ "$?" == 0 ]; then
        log_success "_has_records works!"
    else
        log_failure "_has_records failed!"
    fi
}

test_has_records(){
    _test_has_records '{"resourceRecords":[]}' 1
    _test_has_records '{"resourceRecords":["foo","bar"]}' 0
}

_test_add_record_to_zone(){
    local zone=$1
    local record=$2
    local resp=`_add_record_to_zone "$zone" "$record"`

    #echo $resp
    #echo $3

    assert_eq "$resp" "$3"
    if [ "$?" == 0 ]; then
        log_success "_add_record_to_zone works!"
    else
        log_failure "_add_record_to_zone failed!"
        echo "Expected: $3"
        echo "Got:      $resp"
    fi
}

test_add_record_to_zone(){
    _test_add_record_to_zone '{"resourceRecords":[]}' '{"foo":"bar"}' '{"resourceRecords":[{"foo":"bar"}]}'
    _test_add_record_to_zone '{"resourceRecords":[{"foo":"bar"}]}' '{"foobar":"barbar"}' '{"resourceRecords":[{"foo":"bar"},{"foobar":"barbar"}]}'
}


test_update_record(){
    local zone='{"resourceRecords":[{"name":"test","value":"127.0.0.1"}]}'
    local resp=`_update_record "$zone" 'test' '8.8.8.8'`
    local fixture='{"resourceRecords":[{"name":"test","value":"8.8.8.8"}]}'

    #echo $resp
    #echo $fixture

    assert_eq "$resp" "$fixture"
    if [ "$?" == 0 ]; then
        log_success "_update_record works!"
    else
        log_failure "_update_record failed!"
        echo "Expected: $fixture"
        echo "Got:      $resp"
    fi
}

test_create_object(){
    local resp=`_create_object "test01" "127.0.0.1" "120"`
    local fixture='{ "name": "test01", "ttl": 120, "type": "A", "value": "127.0.0.1" }'

    #echo $resp
    #echo $fixture

    assert_eq "$resp" "$fixture"
    if [ "$?" == 0 ]; then
        log_success "_create_object works!"
    else
        log_failure "_create_object failed!"

        echo $resp
    fi
}

test_get_origin(){
    local fixture='{"origin":"ns1.example.org"}'
    local resp=`_get_origin "$fixture"`

    assert_eq "$resp" "ns1.example.org"
    if [ "$?" == 0 ]; then
        log_success "_get_origin works!"
    else
        log_failure "_get_origin failed!"
    fi
}

test_get_records(){
    local expected='[{"type":"A","name":"test1"}]'
    local fixture="{\"resourceRecords\":$expected}"

    local records=`_get_records "$fixture"`

    assert_eq "$expected" "$records"
    if [ "$?" == 0 ]; then
        log_success "_get_records works!"
    else
        log_failure "_get_records failed!"
        echo "Expected: $expected"
        echo "Got:      $records"
    fi
}

test_zone_to_request_payload(){
    local zone='{
        "created": "blah",
        "foo": "bar",
        "origin":"ns.example.org",
        "resourceRecords":[{"type":"A","value":"127.0.0.1","name":"foo"}]
    }'

    local expected='{ "origin":"ns.example.org", "resourceRecords":[{"type":"A","value":"127.0.0.1","name":"foo"}] }'

    local resp=`_zone_to_request_payload "$zone"`

    assert_eq "$expected" "$resp"
    if [ "$?" == 0 ]; then
        log_success "_zone_to_request_payload works!"
    else
        log_failure "_zone_to_request_payload failed!"
        echo "Zone: $zone"
        echo "Expected:"
        echo "$expected"
        echo "Resp:"
        echo "$resp"
        echo "====================="
    fi
}

_test_update_zone(){
    local expected=$1
    local zone=$2
    local record=$3

    local resp=`_update_zone "$zone" "$record"`

    assert_eq "$expected" "$resp"
    if [ "$?" == 0 ]; then
        log_success "_update_zone works!"
    else
        log_failure "_update_zone failed!"
        echo "Zone:   $zone"
        echo "Record: $record"
        echo "====================="
        echo "Expected:"
        echo "$expected"
        echo "Resp:"
        echo "$resp"
        echo "====================="
    fi
}

test_update_zone(){
    # this is our fixture record
    local record=`_create_object "foo" "127.0.0.1" "120"`

    # zone 1 - no records, we add a new one
    local zone_1='{"origin":"ns.example.org","resourceRecords":[]}'
    local expected_1='{"origin":"ns.example.org","resourceRecords":[{"name":"foo","ttl":120,"type":"A","value":"127.0.0.1"}]}'

    # zone 2 - has records, we add another one
    local zone_2='{"origin":"ns.example.org","resourceRecords":[{"name":"bar","ttl":120,"type":"A","value":"127.0.0.2"}]}'
    local expected_2='{"origin":"ns.example.org","resourceRecords":[{"name":"bar","ttl":120,"type":"A","value":"127.0.0.2"},{"name":"foo","ttl":120,"type":"A","value":"127.0.0.1"}]}'

    # zone 3 - has records, and an existing, so we update (-> IP)
    local zone_3='{"origin":"ns.example.org","resourceRecords":[{"name":"foo","ttl":120,"type":"A","value":"127.0.0.2"}]}'
    local expected_3='{"origin":"ns.example.org","resourceRecords":[{"name":"foo","ttl":120,"type":"A","value":"127.0.0.1"}]}'

    _test_update_zone "$expected_1" "$zone_1" "$record"
    _test_update_zone "$expected_2" "$zone_2" "$record"
    _test_update_zone "$expected_3" "$zone_3" "$record"
}

_test_delete_record(){
    local zone=$1
    local expected=$2
    local record=$3

    local resp=`_delete_record "$zone" "$record"`

    assert_eq "$expected" "$resp"
    if [ "$?" == 0 ]; then
        log_success "_delete works!"
    else
        log_failure "_delete failed!"
        echo "Zone:   $zone"
        echo "Record: $record"
        echo "====================="
        echo "Expected:"
        echo "$expected"
        echo "Resp:"
        echo "$resp"
        echo "====================="
    fi
}

test_delete_record(){
    local zone_1='{"resourceRecords":[{"name":"foo"}]}'
    local expected_1='{"resourceRecords":[]}'

    local zone_2='{"resourceRecords":[{"name":"bar"},{"name":"foo"}]}'
    local expected_2='{"resourceRecords":[{"name":"bar"}]}'

    local record="foo"

    _test_delete_record "$zone_1" "$expected_1" "$record"
    _test_delete_record "$zone_2" "$expected_2" "$record"
}

test_build_call
test_create_record
test_has_records
test_add_record_to_zone
test_update_record
test_create_object
test_get_origin
test_get_records
test_zone_to_request_payload
test_update_zone
test_delete_record