#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

# Feature options are exposed as environment variables (tfenv-version -> TFENV_VERSION, etc.)
TFENV_VERSION="${TFENV_VERSION:-3.2.2}"
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.5.5}"

TFENV_ROOT=/opt/tfenv
BIN_DIR=/usr/local/bin
# Must match containerEnv.TF_PLUGIN_CACHE_DIR in devcontainer-feature.json.
PLUGIN_CACHE_DIR=/opt/terraform/plugin-cache
REMOTE_USER="${_REMOTE_USER:-root}"

log() { printf '[terraform-tools] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(id -u)" -eq 0 ]] || die "Run this installer as root."
trap 'log "Installation failed at line $LINENO."' ERR

# tfenv clones with git and unzips Terraform archives.
missing=()
for dep in git curl unzip; do
    have "$dep" || missing+=("$dep")
done
if ((${#missing[@]})); then
    log "Installing missing dependencies: ${missing[*]}"
    apt-get update -y
    apt-get install -y --no-install-recommends "${missing[@]}"
fi

if [[ -x "$TFENV_ROOT/bin/tfenv" ]]; then
    log "tfenv already installed at $TFENV_ROOT; skipping."
else
    log "Installing tfenv v${TFENV_VERSION}."
    git clone --depth 1 --branch "v${TFENV_VERSION}" \
        https://github.com/tfutils/tfenv.git "$TFENV_ROOT"
fi

# Symlinks let the tfenv shims resolve TFENV_ROOT from their real location.
for f in "$TFENV_ROOT"/bin/*; do
    ln -sfn "$f" "$BIN_DIR/$(basename "$f")"
done

if [[ -x "$TFENV_ROOT/versions/$TERRAFORM_VERSION/terraform" ]]; then
    log "Terraform ${TERRAFORM_VERSION} already installed; skipping."
else
    log "Installing Terraform ${TERRAFORM_VERSION} with tfenv."
    "$TFENV_ROOT/bin/tfenv" install "$TERRAFORM_VERSION"
fi

"$TFENV_ROOT/bin/tfenv" use "$TERRAFORM_VERSION"

# Let the remote user install other Terraform versions and change the default.
chown -R "$REMOTE_USER" "$TFENV_ROOT/versions"
chown "$REMOTE_USER" "$TFENV_ROOT/version"

install -d -m 0755 -o "$REMOTE_USER" "$PLUGIN_CACHE_DIR"

tfenv --version
terraform version

log "Terraform tools install complete."
