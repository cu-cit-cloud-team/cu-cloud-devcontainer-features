#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

log() { printf '[aws-mcps] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(id -u)" -eq 0 ]] || die "Run this installer as root."

# Work out which prerequisites are missing, then install them in one pass.
pkgs=()
have curl || pkgs+=(curl)
if ! have python3; then
  pkgs+=(python3 python3-pip)
elif ! have pip3; then
  pkgs+=(python3-pip)
fi

if ((${#pkgs[@]} > 0)); then
  log "Installing missing packages: ${pkgs[*]}"
  if have apt-get; then
    apt-get update && apt-get install -y --no-install-recommends "${pkgs[@]}"
  elif have apk; then
    apk add --no-cache "${pkgs[@]}"
  elif have dnf; then
    dnf install -y "${pkgs[@]}"
  else
    die "No supported package manager; install manually: ${pkgs[*]}"
  fi
fi

trap 'log "Installation failed at line $LINENO."' ERR

if have uvx; then
  log "uvx already installed; skipping."
else
  log "Installing uv/uvx."
  # Unmanaged install puts uv and uvx in /usr/local/bin for all users and skips shell profile edits.
  curl -LsSf https://astral.sh/uv/install.sh | UV_UNMANAGED_INSTALL=/usr/local/bin sh
fi

if have iam-policy-autopilot; then
  log "iam-policy-autopilot already installed; skipping."
else
  log "Installing iam-policy-autopilot."
  # Newer Debian/Ubuntu pythons are externally managed (PEP 668), so allow system install.
  PIP_BREAK_SYSTEM_PACKAGES=1 PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_NO_CACHE_DIR=1 \
    pip3 install --quiet iam-policy-autopilot
fi

uvx --version
iam-policy-autopilot --version

log "AWS MCP tools install complete."
