#!/bin/bash
set -e

source dev-container-features-test-lib

check "tfenv is installed" \
    bash -c "tfenv --version | grep 'tfenv'"

check "Terraform default version is installed" \
    bash -c "terraform version | grep 'Terraform v'"

check "TF_PLUGIN_CACHE_DIR is set" \
    bash -c "[ \"\$TF_PLUGIN_CACHE_DIR\" = /opt/terraform/plugin-cache ]"

check "Plugin cache directory exists" \
    test -d /opt/terraform/plugin-cache

reportResults
