# Installing Nixotic
Covers provisioning a new host with nixos-anywhere from the `cre8r` driver
VM, the one-time bootstrap of `cre8r` itself, and the WSL install path.
Also covers ZFS disk layout and ongoing ZFS operations.


## Read This First
Three rules matter more than anything else:
1. New machines are installed **from another machine** (normally `cre8r`),
   never by typing on the new machine itself. The new machine only ever
   boots the stock NixOS ISO and waits.
2. Nothing needs to be pushed before installing. nixos-anywhere reads the
   **local checkout** at `~/.nixotic`, WIP branch and all. Push after the
   install succeeds.
3. Nothing needs to be reconciled after installing. The hardware config is
   written into the local checkout *before* the install, `networking.hostId`
   is a random permanent value chosen at scaffold time, and
   `boot.resumeDevice` uses a disko partition label that is known before the
   disk even exists.


## Provision a New Host from cre8r
Total hands-on time at the new machine: about two minutes. Everything else
happens at `cre8r` (or any managed machine — the steps are identical).

### Step 1 — Boot the target on the NixOS ISO
Write the standard NixOS ISO (minimal is fine) to a USB stick and boot the
new machine from it. Log in as `nixos` (no password).

Give root a password and note the IP address:

```bash
sudo passwd root      # nixos-anywhere connects as root
ip a                  # note the IP, e.g. 192.168.1.50
```

Ethernet with DHCP comes up automatically. Verify:

```bash
curl -fsSI https://github.com >/dev/null && echo ok
```

Expected: `ok`.

**What can go wrong here:**
- *No IP shown*: Wi-Fi needs manual setup on the minimal ISO — run
  `sudo systemctl start wpa_supplicant`, then `wpa_cli` →
  `add_network` / `set_network 0 ssid "<SSID>"` /
  `set_network 0 psk "<password>"` / `enable_network 0` / `quit`.
- *Machine won't boot the USB*: check UEFI boot order and disable Secure
  Boot.

That is all the typing the new machine ever gets. Walk away from it.

### Step 2 — Scaffold the host (on cre8r)
```bash
cd ~/.nixotic
git checkout stable && git pull --ff-only
scripts/Prepare-NewHost.sh <newhost>
```

Expected: `Done. Scaffolded hosts/<newhost>/ ...` and a new WIP branch
`wip/YYYYMMDD-XXXXXXX` holding one commit. The random `hostId` it prints is
the **permanent** value for this host — it never changes.

**What can go wrong here:**
- *`error: working tree is dirty`*: commit or stash first; prepare refuses
  to scaffold on top of unrelated changes.
- *`error: must be on 'stable' branch`*: `git checkout stable` and re-run.
- *`error: hosts/<newhost>/ already exists`*: pick another name, or delete
  the stale directory if it was an abandoned attempt.

### Step 3 — Point disk.nix at the right disk
Look at the target's disks over SSH, then set the device:

```bash
ssh root@<target-ip> lsblk -o NAME,SIZE,MODEL,TYPE
```

Expected: the target's disks, e.g. `nvme0n1  931.5G  ...  disk`.

Edit `hosts/<newhost>/disk.nix` and set `disk.main.device` to match
(e.g. `/dev/nvme0n1`). Adjust partition sizes for the actual disk size if
needed. Then review `hosts/<newhost>/configuration.nix` for anything
obviously wrong for this machine (GPU block, timezone, stateVersion) —
but remember: **only the disk layout must be right now**; everything else
is an ordinary post-boot edit.

Commit what you changed:

```bash
git add hosts/<newhost>/ && git commit -m "feat(host): configure <newhost> disk layout"
```

**What can go wrong here:**
- *`ssh: connection refused`*: sshd starts automatically on the ISO, but
  root needs the password from Step 1 — did `sudo passwd root` happen?
- *Wrong device chosen*: this is the one destructive mistake available in
  the whole flow. disko will erase whatever `disk.main.device` names,
  without asking. Double-check against the `MODEL` and `SIZE` columns.

### Step 4 — Install (the walk-away step)
```bash
cd ~/.nixotic
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<newhost> \
  --generate-hardware-config nixos-generate-config hosts/<newhost>/hardware-configuration.nix \
  root@<target-ip>
```

What happens, unattended: nixos-anywhere runs `nixos-generate-config` on the
target and writes the result into `hosts/<newhost>/hardware-configuration.nix`
in this checkout; partitions the disk with disko; builds the system; copies it
over; installs the bootloader; reboots the target into the finished system. Go
for a walk. On a typical machine this takes 10–30 minutes.

Expected final output: `installation finished!` followed by the reboot.

**What can go wrong here:**
- *Host key prompt*: answer `yes`; the ISO generates a fresh host key each
  boot. If a previous attempt left a stale entry:
  `ssh-keygen -R <target-ip>`.
- *disko fails*: the target is still sitting on the live ISO, untouched or
  partially partitioned — nothing is lost. Fix `disk.nix`, commit, re-run
  the same command.
- *`error: The 'fileSystems' option does not specify your root file
  system`*: the host's `disk.nix` sets `disko.enableConfig = false`, so
  disko emits no `fileSystems`, and `nixos-generate-config` runs *before*
  the disk is partitioned so it can't emit them either. The host must let
  disko own the mounts — `disko.enableConfig = true` (the default).
  `Prepare-NewHost.sh` sets this for scaffolded hosts; only a host whose
  `hardware-configuration.nix` was hand-generated on a running machine
  (e.g. `ambul8r`) may keep it `false`.
- *Build is too heavy for cre8r*: add `--build-on-remote` to build on the
  target instead.
- *`error: flake ... is dirty`*: uncommitted changes; `git add` them —
  flakes only see tracked files.

### Step 5 — After the install
```bash
git add hosts/<newhost>/hardware-configuration.nix
git commit -m "feat(host): persist generated hardware config for <newhost>"
git reset --soft stable && git commit    # squash WIP into one clean commit
git checkout stable
git merge --ff-only @{-1}
git branch --delete @{-1} 2>/dev/null || true
git push origin stable
```

Then log into the new host (as `axl`) and give it its own checkout for
ongoing updates:

```bash
nix-shell -p git --run 'git clone https://github.com/axler8r/nixotic.git ~/.nixotic'
```

From here on, updates are the normal cycle: edit, `nh os switch`.

Post-install tuning — packages, GPU drivers, NVIDIA PRIME bus IDs
(`lspci` on the running host), keyboard layout — is ordinary configuration
work on a live system. Nothing about it is special to a fresh install.

**What can go wrong here:**
- *New host won't resume from hibernation*: check that
  `boot.resumeDevice` points at `/dev/disk/by-partlabel/disk-main-swap`
  and that the label exists (`ls /dev/disk/by-partlabel/`). Hosts without
  swap should not set `boot.resumeDevice` at all.


## One-Time: Bootstrap cre8r Itself
`cre8r` is a minimal headless NixOS VM on the Proxmox host. It is installed
exactly like any other host — except the driver is `ambul8r`, because cre8r
does not exist yet. This is done once.

1. On Proxmox, create a VM: 2 vCPU, 4 GB RAM, 32 GB disk (VirtIO block),
   UEFI (OVMF) firmware **with the EFI disk added**, and the NixOS ISO
   attached as the CD. Boot it. Two settings are not optional and are the
   two things most likely to be wrong:
   - **BIOS must be OVMF (UEFI), not the default SeaBIOS.** systemd-boot is
     UEFI-only; a SeaBIOS VM installs fine but never boots the result.
   - **When adding the EFI disk, uncheck "Pre-Enroll keys".** That box is
     ticked by default; enrolling keys turns on Secure Boot, which rejects
     the unsigned NixOS ISO and systemd-boot with `Access Denied`.
2. In the Proxmox console for the VM: `sudo passwd root`, then `ip a` and
   note the IP.
3. On ambul8r, confirm the disk name the VM sees:

   ```bash
   ssh root@<vm-ip> lsblk -o NAME,SIZE,TYPE
   ```

   Expected: `vda  32G  disk`. If it shows `sda` instead (VirtIO SCSI),
   change `device` in `hosts/cre8r/disk.nix` to `/dev/sda` and commit.
4. Install from ambul8r:

   ```bash
   cd ~/.nixotic
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#cre8r \
     --generate-hardware-config nixos-generate-config hosts/cre8r/hardware-configuration.nix \
     root@<vm-ip>
   ```
5. After reboot, remove the ISO from the VM in Proxmox. Log in as `axl`
   over SSH (key-only), change the initial console password
   (`passwd`), commit the generated hardware config, merge, push.
6. Give cre8r its working checkout and an SSH key with GitHub access:

   ```bash
   ssh axl@<vm-ip>
   nix-shell -p git --run 'git clone https://github.com/axler8r/nixotic.git ~/.nixotic'
   ssh-keygen -t ed25519 -C "axl@cre8r"
   # add ~/.ssh/id_ed25519.pub to GitHub
   ```

**What can go wrong here:**
- *Console hangs at `SeaBIOS ... Booting from Hard Disk...`*: the VM is on
  legacy SeaBIOS firmware. The install succeeded, but systemd-boot is
  UEFI-only so SeaBIOS finds nothing bootable and stalls forever — this is
  not slowness, it will never boot. Stop the VM, set BIOS to OVMF (UEFI),
  add an EFI disk with **Pre-Enroll keys unchecked**, and boot. No reinstall
  is needed; the disk is already good.
- *OVMF shows `Access Denied` loading the DVD-ROM and `No bootable option
  or device was found`*: Secure Boot is enabled and rejecting the unsigned
  NixOS ISO. Stop the VM, detach and remove the EFI disk, re-add it with
  **Pre-Enroll keys unchecked**, put the CD first in the boot order, and
  boot. The same applies to the installed system — systemd-boot is unsigned
  and needs Secure Boot off.
- *VM boots to a UEFI shell after install*: created without a proper
  OVMF/EFI-disk setup. Recreate with OVMF (UEFI) and an EFI disk;
  `hosts/cre8r/configuration.nix` uses systemd-boot, which is UEFI-only.


## Fallback: No Driver Machine Available
If cre8r and every managed machine are unavailable (first machine ever, or
total loss), any Linux machine that can run `nix` can act as the driver:
install nix, clone the repo, and follow "Provision a New Host from cre8r"
from Step 2. The steps are identical; `cre8r` is a convenience, not a
requirement.


## WSL Hosts (illumin8r)
WSL hosts use a completely different install path. There is no ISO, no disk
layout, no `hardware-configuration.nix`, no ZFS, and no bootloader.
`illumin8r` is always installed this way.

### Prerequisites (Windows side)
1. Enable WSL2: `wsl --install` (or via Windows Features → Virtual Machine
   Platform + Windows Subsystem for Linux).
2. Confirm WSL2 is the default version: `wsl --set-default-version 2`.
3. Download the latest NixOS-WSL release tarball from the
   `nix-community/NixOS-WSL` GitHub releases page.

### Step 1 — Import the NixOS-WSL distribution
From PowerShell or Windows Terminal:

```powershell
wsl --import NixOS $env:LOCALAPPDATA\NixOS <path-to-tarball> --version 2
```

### Step 2 — Start the instance

```powershell
wsl -d NixOS
```

The initial default user is `nixos`.

### Step 3 — Enable Nix flakes
Inside the WSL instance:

```bash
mkdir -p /etc/nix
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
```

### Step 4 — Apply the nixotic configuration
```bash
nix-shell -p git --run 'git clone https://github.com/axler8r/nixotic.git /tmp/nixotic'
sudo nixos-rebuild switch --flake /tmp/nixotic#illumin8r
```

This installs zsh, helix, git, tmux, tig, github-copilot-cli, and Docker,
and sets `axl` as the default WSL user.

### Step 5 — Restart WSL
From PowerShell:

```powershell
wsl --terminate NixOS
wsl -d NixOS
```

After restart the default user is `axl`, systemd is running, and Docker is
active. No reconciliation step is needed — there are no generated values to
patch back.

### Step 6 — Move the repo into the user home
```bash
cp -r /tmp/nixotic ~/.nixotic
```

### Ongoing updates
From inside the WSL instance:

```bash
cd ~/.nixotic
git pull
sudo nixos-rebuild switch --flake .#illumin8r
```


## Disk Layout
The layout below is the `ambul8r` reference; each host declares its own in
`hosts/<hostname>/disk.nix`. The authoritative declaration for `ambul8r` is
[`hosts/ambul8r/disk.nix`](../hosts/ambul8r/disk.nix).

| Partition |  Size | Type | Purpose     |
| --------- | ----: | ---- | ----------- |
| nvme0n1p1 |    5G | vfat | /boot (EFI) |
| nvme0n1p2 |  150G | ext4 | / (root)    |
| nvme0n1p3 |   32G | swap | Hibernation |
| nvme0n1p4 | ~766G | ZFS  | dpool       |

Root and boot stay on ext4 so the ZFS pool can be wiped or transplanted to
another machine without destroying the OS. The Nix store (`/nix`) lives on
`HOSTDATA/nix` so store growth does not pressure the root partition.


## ZFS Pool Structure
The pool is split into `HOSTDATA` and `USERDATA` so that a machine rebuild —
which wipes root — does not touch personal data. `USERDATA` datasets mount
directly into the home directory and survive reinstalls.

```
dpool                                    mountpoint=none
├── HOSTDATA                             mountpoint=none
│   ├── nix                              /nix
│   └── var/lib/docker                   /var/lib/docker
└── USERDATA                             mountpoint=none
    └── home/axl                         mountpoint=none
        ├── Documents                    /home/axl/Documents
        ├── Downloads                    /home/axl/Downloads
        ├── Media                        /home/axl/Media
        ├── Projects                     /home/axl/Projects
        │   ├── AxlER8R                  /home/axl/Projects/AxlER8R
        │   ├── GitHub                   /home/axl/Projects/GitHub
        │   ├── GitLab                   /home/axl/Projects/GitLab
        │   └── Sandbox                  /home/axl/Projects/Sandbox
        └── Vaults                       /home/axl/Vaults
```

`Projects/` subdirectories are separate datasets so each can have its own
snapshot schedule and quotas independently.

Dataset ownership is set by `systemd.tmpfiles.rules` in each host's
`configuration.nix`, which runs on every boot.


## Required NixOS Configuration
```nix
boot.supportedFilesystems = [ "zfs" "nfs" ];
boot.zfs.forceImportRoot = false;
boot.zfs.extraPools = [ "dpool" ];

# ZFS refuses to import a pool last used by a different machine.
# hostId is how it detects this. Random permanent value set at scaffold time.
networking.hostId = "<random-8-hex-chars>";

# Hibernate target. Deterministic disko partition label — known before install.
boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-swap";

services.zfs = {
  autoScrub.enable = true;
  autoScrub.interval = "monthly";
  trim.enable = true;
};
```


## ZFS Operations
### Common Commands
| Command                                              | Purpose                 |
| ---------------------------------------------------- | ----------------------- |
| `zpool status`                                       | Check pool health       |
| `zpool scrub dpool`                                  | Manual scrub            |
| `zfs list`                                           | List datasets and usage |
| `zfs list -t snapshot`                               | List snapshots          |
| `zfs snapshot dpool/USERDATA/home/axl/Projects@name` | Create snapshot         |
| `zfs rollback dpool/USERDATA/home/axl/Projects@name` | Restore snapshot        |
| `zfs destroy dpool/path@snapshot`                    | Delete snapshot         |
| `systemctl hibernate`                                | Hibernate laptop        |


### Adding New Datasets
Edit the relevant `hosts/<hostname>/disk.nix` to add the dataset — disko creates
it on the next fresh install. To add a dataset on a running system without
reinstalling:

```bash
# Inherits mountpoint from parent (e.g., a new project under Projects/)
sudo zfs create dpool/USERDATA/home/axl/Projects/NewProject
sudo chown axl:users /home/axl/Projects/NewProject

# Top-level dataset with an explicit mountpoint
sudo zfs create -o mountpoint=/home/axl/NewFolder dpool/USERDATA/home/axl/NewFolder
sudo chown axl:users /home/axl/NewFolder
```

Then add the corresponding entry to `disk.nix` and `systemd.tmpfiles.rules`
to keep the declaration in sync with reality.


### Dataset Recovery
If datasets are accidentally destroyed, use
[`files/zsh/functions/New-ZfsLayout`](../files/zsh/functions/New-ZfsLayout)
to recreate them without a full reinstall:

```bash
sudo New-ZfsLayout    # recreates missing datasets, skips existing ones
```
