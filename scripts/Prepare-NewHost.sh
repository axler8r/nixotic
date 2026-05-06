#!/usr/bin/env bash
set -euo pipefail

# Re-exec under nix-shell if git is missing (only once, guarded by sentinel).
if [[ -z "${NIXOTIC_HAS_GIT:-}" ]] && ! command -v git >/dev/null 2>&1; then
    export NIXOTIC_HAS_GIT=1
    exec nix-shell -p git --run "$(printf '%q ' "$0" "$@")"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/preflight.sh"

REPO_URL="https://github.com/axler8r/nixotic"
WORK_DIR="${HOME}/.nixotic"
TEMPLATE="ambul8r"
NEWHOST=""
NO_COMMIT=false


# Usage --------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
usage: $(basename "$0") <hostname> [options]

Scaffold a new NixOS host in the local nixotic checkout and commit it on
a WIP branch. Does not push — push is always done manually.

options:
  --from <template>   Host to copy as template (default: ambul8r)
  --no-commit         Scaffold files but skip the WIP branch and commit

example:
  nix run github:axler8r/nixotic#prepare -- servr8r
  $(basename "$0") servr8r --from ambul8r
EOF
    exit 0
fi


# Argument parsing ---------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --from)       TEMPLATE="${2:?--from requires a hostname}"; shift 2 ;;
        --no-commit)  NO_COMMIT=true; shift ;;
        --help|-h)    exec "$0" --help ;;
        -*)           echo "error: unknown option: $1" >&2; exit 1 ;;
        *)
            if [[ -z "${NEWHOST}" ]]; then
                NEWHOST="$1"
            else
                echo "error: unexpected argument: $1" >&2; exit 1
            fi
            shift ;;
    esac
done

if [[ -z "${NEWHOST}" ]]; then
    echo "error: hostname is required" >&2
    echo "  usage: $(basename "$0") <hostname>" >&2
    exit 1
fi


# Preflight ----------------------------------------------------------------

echo "==> Checking prerequisites..."
nixotic_preflight


# Working directory --------------------------------------------------------

if [[ -d "${WORK_DIR}/.git" ]]; then
    echo "==> Using existing checkout at ${WORK_DIR}..."
else
    echo "==> Cloning nixotic to ${WORK_DIR}..."
    git clone "${REPO_URL}" "${WORK_DIR}"
fi

cd "${WORK_DIR}"


# Guard: refuse dirty worktree -----------------------------------------

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "error: working tree is dirty; commit or stash changes first" >&2
    git status --short >&2
    exit 1
fi


# Guard: must be on stable -----------------------------------------------

CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [[ "${CURRENT_BRANCH}" != "stable" ]]; then
    echo "error: must be on 'stable' branch (currently on '${CURRENT_BRANCH:-detached HEAD}')" >&2
    echo "  Run: git checkout stable" >&2
    exit 1
fi


# Guard: host must not already exist -------------------------------------

if [[ -d "hosts/${NEWHOST}" ]]; then
    echo "error: hosts/${NEWHOST}/ already exists" >&2
    echo "  Remove it first, or choose a different hostname." >&2
    exit 1
fi


# Guard: template must exist ---------------------------------------------

if [[ ! -d "hosts/${TEMPLATE}" ]]; then
    echo "error: template host 'hosts/${TEMPLATE}/' not found" >&2
    exit 1
fi


# Scaffold -----------------------------------------------------------------

echo "==> Scaffolding hosts/${NEWHOST}/ from ${TEMPLATE}..."

mkdir -p "hosts/${NEWHOST}"

cp "hosts/${TEMPLATE}/configuration.nix" "hosts/${NEWHOST}/configuration.nix"
cp "hosts/${TEMPLATE}/disk.nix"          "hosts/${NEWHOST}/disk.nix"

# Placeholder hardware-configuration.nix — replaced after install.
cat > "hosts/${NEWHOST}/hardware-configuration.nix" <<NIXEOF
# Placeholder hardware configuration for ${NEWHOST}
#
# REPLACE THIS FILE after install:
#   sudo cp /etc/nixos/hardware-configuration.nix \\
#       ~/.nixotic/hosts/${NEWHOST}/hardware-configuration.nix
#
# This placeholder allows the flake to evaluate before the host is installed.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
NIXEOF


# Patch hostName and hostId ----------------------------------------------

NEW_HOST_ID="$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 8)"

sed -i \
    "s|networking\.hostName = \"[^\"]*\"|networking.hostName = \"${NEWHOST}\"|" \
    "hosts/${NEWHOST}/configuration.nix"

if grep -q 'networking\.hostId' "hosts/${NEWHOST}/configuration.nix"; then
    sed -i \
        "s|networking\.hostId = \"[^\"]*\"|networking.hostId = \"${NEW_HOST_ID}\"|" \
        "hosts/${NEWHOST}/configuration.nix"
else
    # Template did not have hostId; insert it after the hostName line.
    sed -i \
        "/networking\.hostName/a\\  networking.hostId = \"${NEW_HOST_ID}\";  # from: head -c 8 /etc/machine-id" \
        "hosts/${NEWHOST}/configuration.nix"
fi


# Register in flake.nix --------------------------------------------------

LAST_MKHOST_LINE="$(awk '/mkHost/ && !/^[[:space:]]*#/ {last=NR} END {print last}' flake.nix)"

if [[ -z "${LAST_MKHOST_LINE}" ]]; then
    echo "error: could not locate mkHost entry in flake.nix; add the entry manually:" >&2
    echo "  ${NEWHOST} = mkHost ./hosts/${NEWHOST}/configuration.nix;" >&2
    exit 1
fi

sed -i "${LAST_MKHOST_LINE}a\\        ${NEWHOST} = mkHost .\/hosts\/${NEWHOST}\/configuration.nix;" \
    flake.nix


# Validate ---------------------------------------------------------------

echo "==> Validating flake..."
nix flake check --no-build


# Commit -----------------------------------------------------------------

if [[ "${NO_COMMIT}" == "true" ]]; then
    echo "==> Skipping commit (--no-commit)."
else
    WIP_BRANCH="wip/$(date +%Y%m%d)-$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 7)"
    git checkout -b "${WIP_BRANCH}"
    git add "hosts/${NEWHOST}/" flake.nix
    git commit -m "feat(host): scaffold ${NEWHOST} from ${TEMPLATE}"
    echo ""
    echo "==> Committed to ${WIP_BRANCH}."
fi


# Handoff ----------------------------------------------------------------

cat <<EOF

Done. Scaffolded hosts/${NEWHOST}/ from ${TEMPLATE}.
hostId set to: ${NEW_HOST_ID}

Review and edit hosts/${NEWHOST}/configuration.nix:
  networking.hostName         already set to "${NEWHOST}"
  networking.hostId           set to "${NEW_HOST_ID}" (placeholder — see NOTE below)
  boot.resumeDevice           leave as placeholder; installer will patch it
  boot.loader.*               adjust if not EFI / systemd-boot
  services.xserver.videoDrivers  remove NVIDIA block if host has no NVIDIA GPU
  hardware.nvidia.*           remove or rewrite for the actual GPU
  hardware.nvidia.prime.*     update bus IDs from lspci, or remove
  services.xserver.xkb.layout set keyboard layout if not "nz"
  time.timeZone               update if not "Pacific/Auckland"
  system.stateVersion         set to the NixOS release being installed
  users.users.axl.packages    trim/extend for this host's role
  disk.nix: disk.main.device  verify with lsblk on the new machine

NOTE: networking.hostId should match head -c 8 /etc/machine-id on the
      installed system. The installer (scripts/Install-NixOS.sh) will
      patch it automatically. After first boot, verify it matches and
      commit the corrected value (Phase C).

Installation paths:
  Bare metal (nixotic installer):
    sudo -E nix run github:axler8r/nixotic#install -- ${NEWHOST}

  Already-installed NixOS (adopt into nixotic):
    sudo nixos-rebuild switch --flake ~/.nixotic#${NEWHOST}

The WIP commit lives at ${WORK_DIR}.
Push is always manual — transport to a machine with push access first:

  USB:  cd ${WORK_DIR}
        git format-patch stable..HEAD -o /mnt/usb/
        # on managed machine: git am /mnt/usb/*.patch

  scp:  scp -r ${WORK_DIR} axl@<managed-machine>:/tmp/nixotic-newhost
        # on managed machine: cherry-pick or git am the commit

Then on the managed machine: curate, ff-merge to stable, git push origin stable.
The install app fetches the published GitHub revision — push before booting the installer.
EOF
