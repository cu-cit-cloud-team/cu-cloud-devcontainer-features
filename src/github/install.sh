#!/bin/sh
set -eu

# ssh-keyscan ships in the OpenSSH client package, which is named differently per distro.
if ! command -v ssh-keyscan >/dev/null 2>&1; then
  echo "Installing missing prerequisite: ssh-keyscan"
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-client
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y openssh-clients
  elif command -v yum >/dev/null 2>&1; then
    yum install -y openssh-clients
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache openssh-client
  else
    echo "Error: ssh-keyscan is missing and no supported package manager was found" >&2
    exit 1
  fi
fi

mkdir -p /etc/ssh
if [ ! -e /etc/ssh/ssh_known_hosts ]; then
    touch /etc/ssh/ssh_known_hosts
    chown root:root /etc/ssh/ssh_known_hosts
    chmod 0644 /etc/ssh/ssh_known_hosts
fi

ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts
