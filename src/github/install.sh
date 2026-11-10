#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc/ssh
if [ ! -e /etc/ssh/ssh_known_hosts ]; then
    touch /etc/ssh/ssh_known_hosts
    chown root:root /etc/ssh/ssh_known_hosts
    chmod 0644 /etc/ssh/ssh_known_hosts
fi

ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts
