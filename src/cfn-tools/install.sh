#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

# Feature options are exposed as environment variables (rain-version -> RAIN_VERSION, etc.)
RAIN_VERSION="${RAIN_VERSION:-1.24.4}"
YQ_VERSION="${YQ_VERSION:-4.54.1}"
UPDATE_SPECS="${UPDATE_SPECS:-background}"

PREFIX=/usr/local/share/cfn-tools
VENV="$PREFIX/venv"
REMOTE_USER="${_REMOTE_USER:-root}"

log() { printf '[cfn-tools] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(id -u)" -eq 0 ]] || die "Run this installer as root."

# Work out which prerequisites are missing, then install them in one pass.
need_curl=false need_python=false need_venv=false
have curl || need_curl=true
have python3 || need_python=true
$need_python || python3 -m venv --help >/dev/null 2>&1 || need_venv=true

if $need_curl || $need_python || $need_venv; then
  pkgs=()
  $need_curl && pkgs+=(curl)
  $need_python && pkgs+=(python3 python3-pip)
  if have apt-get; then
    # Debian/Ubuntu ship venv separately from python3
    if $need_python || $need_venv; then pkgs+=(python3-venv); fi
    log "Installing missing packages: ${pkgs[*]}"
    apt-get update && apt-get install -y --no-install-recommends "${pkgs[@]}"
  elif ((${#pkgs[@]} == 0)); then
    die "python3 venv module is missing and cannot be installed automatically."
  elif have apk; then
    log "Installing missing packages: ${pkgs[*]}"
    apk add --no-cache "${pkgs[@]}"
  elif have dnf; then
    log "Installing missing packages: ${pkgs[*]}"
    dnf install -y "${pkgs[@]}"
  else
    die "No supported package manager; install manually: ${pkgs[*]}"
  fi
fi

case "$UPDATE_SPECS" in
    background|none) ;;
    *) die "Invalid update-specs value: $UPDATE_SPECS" ;;
esac

case "$(uname -m)" in
    x86_64|amd64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) die "Unsupported architecture: $(uname -m)" ;;
esac

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
trap 'log "Installation failed at line $LINENO."' ERR

download() {
    curl --fail --location --silent --show-error \
        --retry 3 --connect-timeout 20 \
        --proto '=https' --proto-redir '=https' \
        --output "$2" "$1"
}

install -d -m 0755 "$PREFIX"

if have cfn-lint && have cfn-flip; then
    log "cfn-lint and cfn-flip already installed; skipping."
else
    log "Installing cfn-lint and cfn-flip."
    python3 -m venv "$VENV"
    "$VENV/bin/pip" install --quiet --disable-pip-version-check --no-cache-dir \
        --upgrade pip cfn-lint cfn-flip
    ln -sfn "$VENV/bin/cfn-lint" /usr/local/bin/cfn-lint
    ln -sfn "$VENV/bin/cfn-flip" /usr/local/bin/cfn-flip
fi

if have rain; then
    log "rain already installed; skipping."
else
    log "Installing rain v${RAIN_VERSION} (${ARCH})."
    rain_name="rain-v${RAIN_VERSION}_linux-${ARCH}"
    download "https://github.com/aws-cloudformation/rain/releases/download/v${RAIN_VERSION}/${rain_name}.zip" \
        "$work/rain.zip"
    python3 -m zipfile -e "$work/rain.zip" "$work"
    install -m 0755 "$work/${rain_name}/rain" /usr/local/bin/rain
fi

if have yq; then
    log "yq already installed; skipping."
else
    log "Installing yq v${YQ_VERSION} (${ARCH})."
    download "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}" \
        "$work/yq"
    install -m 0755 "$work/yq" /usr/local/bin/yq
fi

# Lifecycle hook referenced by postCreateCommand in devcontainer-feature.json.
# It runs as the container user (cfn-lint caches schemas in ~/.cache/aws/cfn-lint)
# and detaches the spec update so container creation is not blocked.
cat > "$PREFIX/update-specs-background.sh" <<EOF
#!/usr/bin/env bash
[ "$UPDATE_SPECS" = background ] || exit 0
log="\${TMPDIR:-/tmp}/cfn-lint-update-specs.log"
echo "Updating cfn-lint specs in the background (log: \$log)"
setsid nohup bash -c '
    echo "\$(date) cfn-lint --update-specs started"
    if /usr/local/bin/cfn-lint --update-specs; then
        echo "\$(date) cfn-lint specs updated"
    else
        echo "\$(date) cfn-lint spec update FAILED"
    fi
' > "\$log" 2>&1 < /dev/null &
exit 0
EOF
chmod 0755 "$PREFIX/update-specs-background.sh"

cfn-lint --version
cfn-flip --version
rain --version
yq --version

log "CloudFormation tools install complete."
