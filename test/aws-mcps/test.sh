#!/bin/bash
set -e

source dev-container-features-test-lib

check "uvx is on PATH" \
    bash -c "command -v uvx"

check "uvx reports its version" \
    bash -c "uvx --version | grep -E '^uvx [0-9]+\.[0-9]+'"

check "iam-policy-autopilot is on PATH" \
    bash -c "command -v iam-policy-autopilot"

check "iam-policy-autopilot reports its version" \
    bash -c "iam-policy-autopilot --version | grep -E '^iam-policy-autopilot [0-9]+\.[0-9]+'"

reportResults
