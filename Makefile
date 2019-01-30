UNAME_S := $(shell uname -s)

test-unit:
	./tests/test-unit.sh

test-cli:
	./tests/test-cli.sh

test-shell:
	shellcheck -a -x -e SC2005,SC2155,SC2181 autodns-cli

test: test-unit test-cli test-shell

log:
ifeq ($(UNAME_S),Darwin)
	log stream --style syslog --predicate 'eventMessage contains "autodns-cli"' --info --debug
else
	@echo "Currently only works on OSX."
endif
