#!/bin/bash
set -e

source dev-container-features-test-lib

check "uv is on PATH" \
    bash -c "command -v uv"

check "uv reports its version" \
    bash -c "uv --version | grep -E '^uv [0-9]+\.[0-9]+'"

reportResults
