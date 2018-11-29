# AutoDNS Cli (Shell)

A small cli-client for the InternetX AutoDNS API to update a record with an IP address.

## Use-cases

 - starting VMs/servers and automatically provision them with DNS records
 - creating DNS records for domains on the fly
 - dyn (dynamic) DNS client

## Usage

### Configuration

You need to start this with:

```
$ export AUTODNS_USER=your_login
$ export AUTODNS_PASSWORD=your_password
$ export AUTODNS_CONTEXT=4
$ export MY_ZONE=example.org
```

Bonus points: Create an `.autodns-cli.rc` with the above.

### Updating/Creating a record

Then run with:

```
$ ./autodns-cli update foo.example.org 127.0.0.1
```

### Deleting a record

```
$ ./autodns-cli delete foo
```

_Assumption: `foo.example.org` if your zone is `example.org`.

## Dependencies

 - bash
 - curl
 - jq
 - log (OSX)

 ### For tests

  - bats
  - [assert.sh](https://github.com/torokmark/assert.sh)
  - shellcheck


## Debugging

Use charles for debugging and run with:

```
$ WITH_CHARLES=1 ./autodns-cli ...
```
