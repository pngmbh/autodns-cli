UNAME_S := $(shell uname -s)

test:
	./test-unit.sh
	./test-cli.sh
	shellcheck -a -x -e SC2005,SC2155,SC2181 autodns-cli

log:
ifeq ($(UNAME_S),Darwin)
	log stream --style syslog --predicate 'eventMessage contains "autodns-cli"' --info --debug
else
	@echo "Currently only works on OSX."
endif