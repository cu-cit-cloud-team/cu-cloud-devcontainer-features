#!/bin/sh

# -e : The script exits immediately when a command fails (returns a non-zero exit status). 
# -u : The script exits if an unset variable is used.
set -eu

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
