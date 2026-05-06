#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/preflight.sh"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "usage: install <hostname>"
    echo ""
    echo "Partitions the disk, creates the ZFS pool, installs NixOS for the given host."
    echo "Hosts: $(ls "$(dirname "$0")/../hosts/")"
    exit 0
fi

nixotic_preflight

HOST="${1:-}"
if [[ -z "${HOST}" ]]; then
    echo "usage: install <hostname>" >&2
    exit 1
fi

REPO_URL="https://github.com/axler8r/nixotic"
REPO_DIR="/tmp/nixotic"
DISK_CONFIG="${REPO_DIR}/hosts/${HOST}/disk.nix"
HOST_CONFIG="${REPO_DIR}/hosts/${HOST}/configuration.nix"

if [[ -d "${REPO_DIR}" ]]; then
    echo "==> Using pre-populated source at ${REPO_DIR}..."
else
    echo "==> Cloning nixotic..."
    git clone "${REPO_URL}" "${REPO_DIR}"
fi

if [[ ! -f "${DISK_CONFIG}" ]]; then
    echo "error: no disk configuration for host '${HOST}': ${DISK_CONFIG}" >&2
    exit 1
fi

echo "==> Partitioning disk and creating ZFS layout..."
if [[ -n "${NIXOTIC_DISKO:-}" ]]; then
    "${NIXOTIC_DISKO}/bin/disko" --mode destroy,format,mount "${DISK_CONFIG}"
else
    nix run github:nix-community/disko/latest -- \
        --mode destroy,format,mount "${DISK_CONFIG}"
fi

echo "==> Generating hardware configuration..."
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix \
   "${REPO_DIR}/hosts/${HOST}/hardware-configuration.nix"
rm -f /mnt/etc/nixos/configuration.nix

echo "==> Patching swap UUID..."
SWAP_UUID=$(blkid -t TYPE=swap -o value -s UUID | head -1)
if [[ -z "${SWAP_UUID}" ]]; then
    echo "warning: no swap partition found, skipping UUID patch" >&2
else
    sed --in-place \
        "s|boot\.resumeDevice = \"/dev/disk/by-uuid/[^\"]*\"|boot.resumeDevice = \"/dev/disk/by-uuid/${SWAP_UUID}\"|" \
        "${HOST_CONFIG}"
    if ! grep -q "boot\.resumeDevice = \"/dev/disk/by-uuid/${SWAP_UUID}\"" "${HOST_CONFIG}"; then
        echo "error: failed to patch boot.resumeDevice in ${HOST_CONFIG}" >&2
        exit 1
    fi
fi

echo "==> Patching host ID..."
HOST_ID="$(head -c 8 /etc/machine-id 2>/dev/null || true)"
if [[ -z "${HOST_ID}" ]]; then
    echo "warning: /etc/machine-id not found, skipping hostId patch" >&2
else
    sed --in-place \
        "s|networking\.hostId = \"[^\"]*\"|networking.hostId = \"${HOST_ID}\"|" \
        "${HOST_CONFIG}"
    if ! grep -q "networking\.hostId = \"${HOST_ID}\"" "${HOST_CONFIG}"; then
        echo "error: failed to patch networking.hostId in ${HOST_CONFIG}" >&2
        exit 1
    fi
fi

echo "==> Installing NixOS..."
nixos-install --flake "${REPO_DIR}#${HOST}"

echo ""
echo "Done. Reboot, then commit:"
echo "  hosts/${HOST}/hardware-configuration.nix  (real hardware scan)"
echo "  hosts/${HOST}/configuration.nix           (patched swap UUID and hostId)"
