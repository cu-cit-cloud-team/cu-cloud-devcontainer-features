#!/bin/sh

# -e : The script exits immediately when a command fails (returns a non-zero exit status). 
# -u : The script exits if an unset variable is used.
set -eu

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found; installing it"
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl
  else
    echo "Error: curl is missing and no supported package manager was found" >&2
    exit 1
  fi
fi

echo "Installing AWS CLI"

curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash -s -- --system --quiet

echo "AWS CLI install complete"

# Feature options are exposed as environment variables (ssm-session-manager -> SSM_SESSION_MANAGER)
if [ "${SSM_SESSION_MANAGER:-true}" = "true" ]; then
    echo "Installing SSM Session Manager plugin"

    bash "$(dirname "$0")/install-ssm-plugin.sh"

    echo "Installing ssmhost"
    install -m 0755 "$(dirname "$0")/ssmhost" /usr/local/bin/ssmhost

    echo "SSM Session Manager plugin install complete"
else
    echo "Skipping SSM Session Manager plugin (ssm-session-manager is false)"
fi
