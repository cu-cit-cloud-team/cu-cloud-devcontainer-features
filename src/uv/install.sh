#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

log() { printf '[uv] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(id -u)" -eq 0 ]] || die "Run this installer as root."

# uv can fetch its own Python, so only curl and a CA bundle are required from the system.
pkgs=()
have curl || pkgs+=(curl)
[[ -s /etc/ssl/certs/ca-certificates.crt ]] || pkgs+=(ca-certificates)

if ((${#pkgs[@]} > 0)); then
  log "Installing missing packages: ${pkgs[*]}"
  if have apt-get; then
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"
  elif have apk; then
    apk add --no-cache "${pkgs[@]}"
  elif have dnf; then
    dnf install -y "${pkgs[@]}"
  else
    die "No supported package manager; install manually: ${pkgs[*]}"
  fi
fi

trap 'log "Installation failed at line $LINENO."' ERR

if have uv; then
  log "uv  already installed; skipping."
else
  log "Installing uv/uvx."
  # Unmanaged install puts uv and uvx in /usr/local/bin for all users and skips shell profile edits.
  curl -LsSf https://astral.sh/uv/install.sh | UV_UNMANAGED_INSTALL=/usr/local/bin sh
fi

uv --version

log "uv tools install complete."
