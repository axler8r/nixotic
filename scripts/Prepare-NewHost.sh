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
ROLE="workstation"
NEWHOST=""
NO_COMMIT=false
PROFILE="fixed"


# Usage --------------------------------------------------------------------

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
usage: $(basename "$0") <hostname> [options]

Scaffold a new NixOS host in the local nixotic checkout and commit it on
a WIP branch. Does not push — push is always done manually.

options:
  --role workstation|server  Host role (default: workstation)
  --no-commit                Scaffold files but skip the WIP branch and commit
  --profile fixed|portable   Host class (default: fixed)

example:
  nix run github:axler8r/nixotic#prepare -- servr8r --role server
  $(basename "$0") workst8r --profile portable
EOF
    exit 0
fi


# Argument parsing ---------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --role)       ROLE="${2:?--role requires workstation|server}"; shift 2 ;;
        --no-commit)  NO_COMMIT=true; shift ;;
        --profile)    PROFILE="${2:?--profile requires fixed|portable}"; shift 2 ;;
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

if [[ "${PROFILE}" != "fixed" && "${PROFILE}" != "portable" ]]; then
    echo "error: --profile must be 'fixed' or 'portable' (got '${PROFILE}')" >&2
    exit 1
fi

if [[ "${ROLE}" != "workstation" && "${ROLE}" != "server" ]]; then
    echo "error: --role must be 'workstation' or 'server' (got '${ROLE}')" >&2
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


# Guards (commit mode only) -----------------------------------------------
# A --no-commit dry run creates no WIP branch and no commit, so it may run
# from any branch and tolerate a dirty tree — the guards below only matter
# when the script is about to branch and commit.

if [[ "${NO_COMMIT}" != "true" ]]; then
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "error: working tree is dirty; commit or stash changes first" >&2
        git status --short >&2
        exit 1
    fi

    CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
    if [[ "${CURRENT_BRANCH}" != "stable" ]]; then
        echo "error: must be on 'stable' branch (currently on '${CURRENT_BRANCH:-detached HEAD}')" >&2
        echo "  Run: git checkout stable" >&2
        exit 1
    fi
fi


# Guard: host must not already exist -------------------------------------

if [[ -d "hosts/${NEWHOST}" ]]; then
    echo "error: hosts/${NEWHOST}/ already exists" >&2
    echo "  Remove it first, or choose a different hostname." >&2
    exit 1
fi


# Scaffold -----------------------------------------------------------------

echo "==> Scaffolding hosts/${NEWHOST}/ as a ${ROLE}..."

mkdir -p "hosts/${NEWHOST}"

if [[ "${ROLE}" == "workstation" ]]; then
    ROLE_MODULE="workstation"
    SSH_BLOCK=""
else
    ROLE_MODULE="base"  # until hosts/common/server.nix exists
    SSH_BLOCK='
  # Headless host — reachable over SSH from first boot, key-only.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
'
fi

NEW_HOST_ID="$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom | head -c 8 || true)"

if [[ -z "${NEW_HOST_ID}" ]]; then
    echo "error: failed to generate host ID" >&2
    exit 1
fi

# Thin host config — the role module owns everything shareable; hardware
# quirks (GPU, resume device, extra pools) are ordinary post-install edits.
cat > "hosts/${NEWHOST}/configuration.nix" <<NIXEOF
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../common/zfs-root.nix
    ../common/${ROLE_MODULE}.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "${NEWHOST}";
  networking.hostId = "${NEW_HOST_ID}";  # random, permanent — ZFS needs stability
${SSH_BLOCK}
  system.stateVersion = "25.11";  # NixOS release being installed; never change after install
}
NIXEOF

# Generate a thin disk.nix wrapper that imports the shared parameterised layout.
if [[ "${PROFILE}" == "portable" ]]; then
    cat > "hosts/${NEWHOST}/disk.nix" <<'NIXEOF'
# Thin wrapper — the layout lives in hosts/common/zfs-root-disk.nix.
# Set `device` to the target disk (see: ssh root@<ip> lsblk) and
# `swapSizeGiB` to at least the machine's RAM (hibernation image).
import ../common/zfs-root-disk.nix {
  device      = "/dev/nvme0n1";
  swap        = "hibernate";
  swapSizeGiB = 64;
}
NIXEOF
else
    cat > "hosts/${NEWHOST}/disk.nix" <<'NIXEOF'
# Thin wrapper — the layout lives in hosts/common/zfs-root-disk.nix.
# Set `device` to the target disk (see: ssh root@<ip> lsblk).
import ../common/zfs-root-disk.nix {
  device = "/dev/nvme0n1";
  swap   = "zram";
}
NIXEOF
fi

# Placeholder hardware-configuration.nix — replaced after install.
cat > "hosts/${NEWHOST}/hardware-configuration.nix" <<NIXEOF
# Placeholder hardware configuration for ${NEWHOST}
#
# Overwritten automatically during install by:
#   nixos-anywhere --generate-hardware-config nixos-generate-config \\
#       hosts/${NEWHOST}/hardware-configuration.nix
#
# fileSystems are intentionally omitted: disko generates them from disk.nix
# (disko.enableConfig = true). This placeholder only lets the flake evaluate
# before the host exists; nixos-generate-config replaces it at install time.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
NIXEOF


# Register in flake.nix --------------------------------------------------

if ! grep -q '# prepare:hosts' flake.nix; then
    echo "error: sentinel '# prepare:hosts' not found in flake.nix; add the entry manually:" >&2
    echo "  ${NEWHOST} = mkHost { hostPath = ./hosts/${NEWHOST}/configuration.nix; };" >&2
    exit 1
fi

if [[ "${ROLE}" == "server" ]]; then
    FLAKE_ENTRY="        ${NEWHOST} = mkHost { hostPath = ./hosts/${NEWHOST}/configuration.nix; role = \"server\"; };"
else
    FLAKE_ENTRY="        ${NEWHOST} = mkHost { hostPath = ./hosts/${NEWHOST}/configuration.nix; };"
fi

sed -i "/# prepare:hosts/a\\${FLAKE_ENTRY}" flake.nix


# Stage new files so Nix can see them (flake evaluates only tracked paths) ---

git add "hosts/${NEWHOST}/" flake.nix


# Validate ---------------------------------------------------------------

echo "==> Validating flake..."
nix flake check --no-build


# Commit -----------------------------------------------------------------

if [[ "${NO_COMMIT}" == "true" ]]; then
    echo "==> Skipping commit (--no-commit)."
else
    WIP_BRANCH="wip/$(date +%Y%m%d)-$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 7 || true)"
    git checkout -b "${WIP_BRANCH}"
    git add "hosts/${NEWHOST}/" flake.nix
    git commit -m "feat(host): scaffold ${NEWHOST} as ${ROLE}"
    echo ""
    echo "==> Committed to ${WIP_BRANCH}."
fi


# Handoff ----------------------------------------------------------------

cat <<EOF

Done. Scaffolded hosts/${NEWHOST}/ as a ${ROLE}.
hostId set to: ${NEW_HOST_ID} (random, permanent — ZFS needs stability, not machine-id derivation)

The scaffold is thin: the role module (hosts/common/${ROLE_MODULE}.nix) owns
everything shareable. Review and edit hosts/${NEWHOST}/configuration.nix:
  boot.loader.*               adjust if not EFI / systemd-boot
  time zone, locale, layout   override here if this host differs from base
  system.stateVersion         set to the NixOS release being installed
  nixpkgs.hostPlatform        set to aarch64-linux for ARM hosts
  disk.nix: device            verify: ssh root@<target-ip> lsblk
  disk.nix: swapSizeGiB       (portable only) set to at least the machine's RAM

Hardware quirks (GPU driver, NVIDIA PRIME bus IDs, resume tweaks) are
ordinary post-install edits on the running system.

Install (target machine booted on the standard NixOS ISO, root password set):

  cd ~/.nixotic
  nix run github:nix-community/nixos-anywhere -- \\
    --flake .#${NEWHOST} \\
    --generate-hardware-config nixos-generate-config hosts/${NEWHOST}/hardware-configuration.nix \\
    root@<target-ip>

See docs/install.md for the full walkthrough. Push is manual, after the
install succeeds: merge the WIP branch to stable (ff-only), then git push.
EOF
