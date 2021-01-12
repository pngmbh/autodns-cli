function _log() {
    local msg=$1
    if [[ "DEBUGSYSLOG" = "true" ]] ;then logger -t "$prog" -i "${prog}: ${msg}";fi 
    if [[ "DEBUGSTDERR" = "true" ]] ;then echo "$msg" >&2 ;fi 
    echo "$msg" >&2
}

# autodns calls
# @test `test_build_call`
# @private
function _build_call() {
	declare -a curl
    local method=$1

    curl+=(curl)
    if [ -n "$WITH_CHARLES" ]; then
        curl+=(--proxy 127.0.0.1:8888 -k)
    fi
    curl+=(--silent)
    curl+=(--show-error)
    curl+=(--user-agent "$prog")
    curl+=(-H "X-Domainrobot-Context:${AUTODNS_CONTEXT}")
	curl+=(-X "$method")
    curl+=(-H 'Accept:application/json')
    if [[ "$method" =~ ^(PUT|POST)$ ]]; then
        curl+=(-H 'Content-Type:application/json')
    fi

	curl+=(-u "${AUTODNS_USER}:${AUTODNS_PASSWORD}")
	curl+=("$endpoint")

	echo "${curl[@]}"
}

# make request and return response
# @TODO integration test
# @private
function _make_request() {
    local cmd="$1"
    local body
    local response

    if [ $# -gt 1 ]; then
        if [ -n "$2" ]; then
            body="$2"
        fi
    fi

    _log "_make_request: $cmd"
    _log "_make_request: $body"

    if [ -n "$body" ]; then
        _log "With body!"
        response=$($cmd -d "$body")
    else
        response=$($cmd)
    fi

    _log "Curl said: $? -> $response"
    if [ $? -ne 0 ]; then
        _log "Error in curl request!"

        return $?
    fi

    local error=$(_validate_response "$response")
    if [ $? -ne 0 ]; then
        echo "$error"
        return $?
    fi

    _log "Validate response: $error ($?) - $response"

    echo "$response"
}

# checks if we encountered an error
# @TODO write unit test
# @private
function _validate_response() {
    local resp=$1

    _log "_validate_response"

    local valid_json=$(echo "$resp" | jq -e)
    if [ $? -ne 0 ]; then
        printf "Invalid or broken JSON (%s): %s" "$valid_json" "$resp"
        return $?
    fi

    local status=$(echo "$resp"|jq -c -r .status.type)
    if [ -z ${status+x} ]; then
        echo "Status not set, something went really wrong!"
        return 1
    fi

    if [ "$status" != "SUCCESS" ]; then
        local message=$(echo "$resp"|jq -r -c '.messages[0].text')
        local code=$(echo "$resp"|jq -r -c '.messages[0].messageCode')

        printf "Request error:\n  Status: %s\n  Message: %s (Code: %s)\n" "$status" "$message" "$code"

        return 1
    fi

    _log "Valid response!"

    return 0
}

# check if a zone has any records so far
# @test `test_has_records`
# @private
function _has_records() {
    local zone=$1
    local count=0
    
    count=$(echo "$zone"|jq '.resourceRecords|length')
    if [[ $count -gt 0 ]]; then
      return 0
    fi

    return 1
}

# @TODO refactor with _has_records?
# @test `test_get_records`
# @private
function _get_records(){
    local zone=$1
    local records

    records="$(echo "$zone"|jq -c -r '.resourceRecords')"
    echo "$records"
}

# replaces IP on an existing record
# @test `test_update_record`
# @private
function _update_record(){
    local data=$1
    local a_record=$2
    local ip=$3

    local records=$(echo "$data"|jq --arg a_record "$a_record" --arg ip "$ip" '.resourceRecords|map(if .name == $a_record then . + {"value": $ip} else . end)')
    tmp=$(mktemp)
    data=$(echo "$data"| jq -c --argjson records "$records" '.resourceRecords = $records' > "$tmp" && cat "$tmp" && rm "$tmp")

    echo "$data"
}

# strips zone-name from it and removes trailing '.' in case
# @test `test_create_record`
# @private
function _create_record() {
    local record
    local domain=$1
    record=${domain/$MY_ZONE/""}

    if [[ "$record" =~ '.'$ ]]; then 
        record=${record%?} # strip trailing dot
    fi
 
    echo "$record"
}

# creates json object for an A-record
# @test `test_create_object`
# @private
function _create_object() {
    local record=$1
    local record_ip=$2
    local record_ttl=$3
    local rrtype=$4
    printf '{ "name": "%s", "ttl": %d, "type": "'$rrtype'", "value": "%s" }' "$record" "$record_ttl" "$record_ip"
}

# Adds a record (JSON object) to a zone (JSON object)
# @test `test_add_record_to_zone`
# @private
function _add_record_to_zone(){
    local data=$1
    local record=$2

    local updated_data=$(echo "$data" | jq -c --argjson record "$record" '.resourceRecords += [$record]')

    echo "$updated_data"
}

# parses origin from a result set
# @test `test_get_origin`
# @private
function _get_origin(){
    local zone=$1
    echo "$(echo "$zone" | jq -r '.origin')"
}

#set -x

# @private
# @uses $MY_ZONE
function _build_filter() {
    local operator='EQUAL'
    printf '{"filters": [{"key": "name", "operator": "%s", "value": "%s"}] }' "$operator" "$MY_ZONE"
}

# check if the zone exists
# @TODO Write integration test
# @private
function _zone_exists() {
    local call=$(_build_call "POST")
    local zone_name=$1
    local origin
    local ns

    _log "_zone_exists"
    _log "zone_name: ${zone_name}"

    local request="$call/zone/_search"
    local filter=$(_build_filter)

    _log "Filter: $filter"

    local zones=$(_make_request "$request" "$filter")
    if [ $? -ne 0 ]; then
        echo "$zones"
        return $?
    fi

    _log "fetch zones: $zones"

    ns=$(echo "$zones" | jq -r '.data[0].virtualNameServer')
    origin=$(echo "$zones"|jq -r '.data[0].origin')

    if [ "$zone_name" != "$origin" ]; then
        return 1
    fi

    echo "$origin/$ns"
}

# return the zone from the API
# @TODO integration test
# @private
function _get_zone() {
    local my_zone="$1"

    local call=$(_build_call "GET")

    local data=$(_make_request "$call/zone/$my_zone")
    _validate_response "$data"
    if [ $? -ne 0 ]; then
        return 1
    fi

    echo "$(echo "$data"|jq -r '.data[0]')"
}

# return only required payload:
# - origin
# - resourceRecords
# @test `test_zone_to_request_payload`
# @private
function _zone_to_request_payload(){
    local zone=$1
    local resp

    origin=$(echo "$zone"|jq -c '.origin')
    records=$(echo "$zone"|jq -c '.resourceRecords')

    printf "{ \"origin\":%s, \"resourceRecords\":%s }" "$origin" "$records"
}

# delete the record by it's name value
#
# @private
function _delete_record(){
    local zone=$1
    local record_name=$2

    local tmp=$(mktemp)
    echo "$(echo "$zone"|jq -r -c --arg record_name "$record_name" 'del(.resourceRecords[]|select(.name==$record_name))' > "$tmp" && cat "$tmp" && rm "$tmp")"
}

# updates the zone object with the given record
# @test `test_update_zone`
# @private
function _update_zone(){
    local zone=$1
    local record=$2

    # try to delete existing record
    # then add record to it

    local name="$(echo "$record"|jq -r '.name')"
    _log "Extracted name: $name (from: $record)"

    local data

    if _has_records "$zone" -eq 0; then
        _log "We have records already, let's delete: .name==$name"

        data=$(_delete_record "$zone" "$name")
    else
        data="$zone"
    fi

    _log "Zone: $data"

    echo "$(_add_record_to_zone "$data" "$record")"
}
