#!/bin/sh

# -e : The script exits immediately when a command fails (returns a non-zero exit status). 
# -u : The script exits if an unset variable is used.
set -eu

# Collect missing prerequisites and install them in a single package-manager call.
missing=""
command -v curl >/dev/null 2>&1 || missing="$missing curl"
command -v unzip >/dev/null 2>&1 || missing="$missing unzip"
command -v gpg >/dev/null 2>&1 || missing="$missing gnupg"

if [ -n "$missing" ]; then
  echo "Installing missing prerequisites:$missing"
  # RPM-based distros name the package gnupg2
  rpm_missing=$(echo "$missing" | sed 's/\bgnupg\b/gnupg2/')
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    # shellcheck disable=SC2086
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates $missing
  elif command -v dnf >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    dnf install -y $rpm_missing
  elif command -v yum >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    yum install -y $rpm_missing
  elif command -v apk >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    apk add --no-cache $missing
  else
    echo "Error: missing$missing and no supported package manager was found" >&2
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
