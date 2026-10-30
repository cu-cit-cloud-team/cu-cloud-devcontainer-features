#!/bin/bash
set -e

source dev-container-features-test-lib

check "cfn-lint is installed" \
    bash -c "cfn-lint --version | grep 'cfn-lint'"

check "cfn-flip is installed" \
    bash -c "cfn-flip --version | grep 'AWS Cloudformation Template Flip'"

check "rain is installed" \
    bash -c "rain --version | grep 'Rain'"

check "yq is installed" \
    bash -c "yq --version | grep 'mikefarah/yq'"

check "update-specs hook is executable" \
    test -x /usr/local/share/cfn-tools/update-specs-background.sh

reportResults
