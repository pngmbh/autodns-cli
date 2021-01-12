# AutoDNS Cli (Shell)

A small cli-client for the InternetX AutoDNS API to update a record with an IP address.

## Use-cases

 - starting VMs/servers and automatically provision them with DNS records
 - creating DNS records for domains on the fly
 - dyn (dynamic) DNS client

## Usage

### Verbosity

log to syslog/logger( attention , your password as well )

```
$ DEBUGSYSLOG=true ./autodns-cli update foo.example.org 127.0.0.1
```
log to STDERR
```
$ DEBUGSTDERR=true ./autodns-cli update foo.example.org 127.0.0.1
```

### Configuration

You need to start this with:

```
$ export AUTODNS_USER=your_login
$ export AUTODNS_PASSWORD=your_password
$ export AUTODNS_CONTEXT=4
$ export MY_ZONE=example.org
```

or alternatively
```
MY_ZONE=example.org AUTODNS_CONTEXT=4 AUTODNS_USER=your_login AUTODNS_PASSWORD=your_password ./autodns-cli update foo.example.org 127.0.0.1
```


Bonus points: Create an `.autodns-cli.rc` with the above.

### Updating/Creating a DNS record ( resource record in autodns )

## BE CAREFUL AS the domain parameter might be prefixed  ( e.g mydomainentry.mydomain.com)

Then run with:

```
$ ./autodns-cli update domain.com 127.0.0.1
```
OR specify the type as last argument

```
$ ./autodns-cli update _amazonses.subdomain "ASDOIJQWDQWDASD+24hjdsf23/" TXT
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
