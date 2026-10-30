#!/bin/bash
set -e

source dev-container-features-test-lib

check "AWS-CLI is installed" \
    bash -c "aws --version | grep 'aws-cli/'"

check "SSM Plugin is installed" \
    bash -c "session-manager-plugin | grep 'installed successfully'"

reportResults