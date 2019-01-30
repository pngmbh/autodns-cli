#!/usr/bin/env bats

@test "test non existing command" {
    run ./autodns-cli blah
    [ "$status" -eq 1 ]
}

@test "test help" {
    run ./autodns-cli help
    [ "$status" -eq 0 ]
}
