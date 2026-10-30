#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

# Keep the requested plugin version separate: sourcing /etc/os-release below
# sets its own VERSION (e.g. "13 (trixie)"), which would clobber this value.
PLUGIN_VERSION="${VERSION:-latest}"

log() { printf '[ssm-plugin] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ "$(id -u)" -eq 0 ]] ||
    die "Run this installer as root."

[[ "$(uname -s)" == Linux ]] ||
    die "Only Linux is supported."

[[ "$PLUGIN_VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] ||
    die "Invalid version: $PLUGIN_VERSION"

[[ -r /etc/os-release ]] ||
    die "Cannot identify the Linux distribution."

. /etc/os-release

case "${ID:-}" in
    amzn)
        [[ "${VERSION_ID:-}" == 2023 ]] ||
            die "Only Amazon Linux 2023 is supported."
        package_family=rpm
        ;;
    rhel)
        package_family=rpm
        ;;
    debian|ubuntu)
        package_family=deb
        ;;
    *)
        die "Unsupported distribution: ${ID:-unknown}"
        ;;
esac

case "$(uname -m)" in
    x86_64|amd64) platform=ubuntu_64bit ;;
    aarch64|arm64) platform=ubuntu_arm64 ;;
    *) die "Unsupported architecture: $(uname -m)" ;;
esac

# Install only missing prerequisites. Include both common DEB decompressors.
packages=()
have curl || packages+=(curl)
have ar   || packages+=(binutils)
have tar  || packages+=(tar)
have xz   || packages+=(xz-utils)
have zstd || packages+=(zstd)

if [[ "$package_family" == deb ]]; then
    dpkg-query -W -f='${Status}' ca-certificates 2>/dev/null |
        grep -qx 'install ok installed' ||
        packages+=(ca-certificates)

    if ((${#packages[@]})); then
        log "Installing prerequisites."
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install \
            -y --no-install-recommends "${packages[@]}"
    fi
else
    # RPM distributions call the xz package "xz", not "xz-utils".
    for i in "${!packages[@]}"; do
        [[ "${packages[$i]}" != xz-utils ]] || packages[$i]=xz
    done

    rpm -q ca-certificates >/dev/null 2>&1 ||
        packages+=(ca-certificates)

    if ((${#packages[@]})); then
        log "Installing prerequisites."
        if have dnf; then
            dnf install -y "${packages[@]}"
        elif have yum; then
            yum install -y "${packages[@]}"
        else
            die "Neither dnf nor yum is available."
        fi
    fi
fi

work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
trap 'log "Installation failed at line $LINENO."' ERR

url="https://s3.amazonaws.com/session-manager-downloads/plugin"
url="$url/$PLUGIN_VERSION/$platform/session-manager-plugin.deb"

log "Downloading Session Manager plugin: $PLUGIN_VERSION ($(uname -m))."

curl --fail --location --silent --show-error \
    --retry 3 --connect-timeout 20 \
    --proto '=https' --proto-redir '=https' \
    --output "$work/plugin.deb" \
    "$url"

member="$(ar t "$work/plugin.deb" |
    awk '/^data\.tar(\..+)?$/ {print; exit}')"

[[ -n "$member" ]] ||
    die "Cannot find the DEB data archive."

mkdir "$work/extracted"
ar p "$work/plugin.deb" "$member" > "$work/$member"
tar -xf "$work/$member" -C "$work/extracted"

payload="$work/extracted/usr/local/sessionmanagerplugin"
binary="$payload/bin/session-manager-plugin"

[[ -x "$binary" ]] ||
    die "Unexpected package layout: plugin executable not found."

# Check runtime compatibility before changing the installed files.
installed_version="$("$binary" --version)" ||
    die "Downloaded plugin cannot run on this system."

destination=/usr/local/sessionmanagerplugin

install -d -m 0755 "$destination" /usr/local/bin
cp -R "$payload/." "$destination/"
ln -sfn \
    "$destination/bin/session-manager-plugin" \
    /usr/local/bin/session-manager-plugin

/usr/local/bin/session-manager-plugin --version

log "Installed Session Manager plugin: $installed_version"