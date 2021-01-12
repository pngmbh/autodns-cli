#commands
sub_delete() {
    local domain=$1

    if [ -z "$domain" ]; then
        echo "Please provide a domain."
        exit 1
    fi

    if [ -z ${MY_ZONE+x} ]; then
        echo "Missing \$MY_ZONE"
        exit 1
    fi

    local request_uri=$(_zone_exists "$MY_ZONE")
    if [ -z ${request_uri+x} ]; then
        printf "Zone does not exist (my_zone: %s, Request URI: %s)" "$MY_ZONE" "$request_uri"
        exit 1
    fi

    local data=$(_get_zone "$request_uri")
    if [ $? -ne 0 ]; then
        printf "Could not retrieve zone: %s" "$data"
        exit $?
    fi

    local a_record=$(_create_record "$domain" "$ip")
    _log "New record: $a_record"

    local payload=$(_delete_record "$data" "$a_record")

    local update_call=$(_build_call "PUT")
    local request_call="$update_call/zone/$request_uri"
    _log "Update call: $request_call"

    local update_request=$(_make_request "$request_call" "$payload")
    if [ $? -ne 0 ]; then
        printf "Update failed: %s" "$update_request"
        exit $?
    fi

    _log "API response (PUT/update): $update_request (Code: $?)"

    echo "Success!"
    exit 0
}
sub_help() {
	echo ""
    echo "$(<./README.md)"
	echo ""
}

# show current zone "info"
sub_show() {
    local request_uri=$(_zone_exists "$MY_ZONE")
    if [ $? -ne 0 ]; then
        echo "$request_uri"
        exit $?
    fi

    local data=$(_get_zone "$request_uri")
    if [ $? -ne 0 ]; then
        echo "$data"
        exit $?
    fi

    echo "$(echo "$data"|jq -C '.')"
}

# add/update a record in the zone
sub_update() {
    local domain=$1
    local ip=$2
    local rrtype=$3


    if [ -z "$domain" ]; then
        echo "Please provide a domain."
        exit 1
    fi

    if [ -z "$ip" ]; then
        echo "Please provide an IP."
        exit 1
    fi

    if [ -z "$rrtype" ]; then
        echo "resource type not set, using A"
        rrtype=A
    fi

    if [ -z ${MY_ZONE+x} ]; then
        echo "Missing \$MY_ZONE"
        exit 1
    fi

    local request_uri=$(_zone_exists "$MY_ZONE")
    if [ -z ${request_uri+x} ]; then
        printf "Zone does not exist (my_zone: %s, Request URI: %s)" "$MY_ZONE" "$request_uri"
        exit 1
    fi

    local data=$(_get_zone "$request_uri")
    if [ $? -ne 0 ]; then
        printf "Could not retrieve zone: %s" "$data"
        exit $?
    fi

    _log "Zone data: $data"

    local new_record=$(_create_record "$domain" "$ip" )
    _log "New record: $new_record"

    local obj=$(_create_object "$new_record" "$ip" "$ttl" "$rrtype")
    _log "Created object: $obj"

    local payload=$(_update_zone "$data" "$obj")
    
    local update_call=$(_build_call "PUT")
    local request_call="$update_call/zone/$request_uri"
    _log "Update call: $request_call"

    local update_request=$(_make_request "$request_call" "$payload")
    if [ $? -ne 0 ]; then
        printf "Update failed: %s" "$update_request"
        exit $?
    fi

    _log "API response (PUT/update): $update_request (Code: $?)"

    echo "Success!"
    exit 0
}
