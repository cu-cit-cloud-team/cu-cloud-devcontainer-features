#!/bin/bash
set -e

source dev-container-features-test-lib

check "known_hosts file exists" \
    test -s /etc/ssh/ssh_known_hosts

check "github.com host key is in known_hosts" \
    bash -c "grep -q '^github.com ' /etc/ssh/ssh_known_hosts"

reportResults
