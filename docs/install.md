# Installing Nixotic
Covers bootstrapping a brand-new host from scratch: defining the host,
installing from the NixOS ISO, and reconciling the generated values after the
first boot. Also covers ZFS disk layout and ongoing ZFS operations.


## Read This First
Three rules matter more than anything else:

1. There is no separate "install plain NixOS first" step in this workflow.
2. `prepare` happens before `install`.
3. The installer fetches from `origin/stable`, so the new host config must be
   pushed before `nix run github:axler8r/nixotic#install -- <newhost>`.

There are two different boots:

1. Boot the installer ISO on the new machine.
2. After `nixos-install` finishes, reboot into the newly installed system.


## Exact Sequence
Follow this sequence exactly on a brand-new machine:

1. Boot the NixOS installer ISO on the target machine.
2. Log in as `nixos`.
3. Bring up networking on the installer ISO.
4. From the installer ISO, inspect the hardware you need to model:
   `lsblk -o NAME,SIZE,MODEL,TYPE`, `lspci`, `ip a`.
5. Leave the installer ISO running. Do not install generic NixOS.
6. On a managed machine, run `nix run github:axler8r/nixotic#prepare -- <newhost>`.
7. Edit `hosts/<newhost>/configuration.nix` and `hosts/<newhost>/disk.nix` so
   they match the new machine.
8. Push that host config to `origin/stable`.
9. Go back to the installer ISO on the new machine.
10. Enable flakes and verify the target disk one more time.
11. Run `sudo -E nix run github:axler8r/nixotic#install -- <newhost>`.
12. Wait for `nixos-install` to finish, then reboot.
13. Log into the newly installed system. This is the first boot.
14. Clone the repo onto the new host, persist the generated hardware config,
    and reconcile the patched values back into `hosts/<newhost>/`.
15. Run `sudo nixos-rebuild switch --flake .#<newhost>` once.
16. Commit and push the reconciled files.
17. From that point on, use `nh os switch` for normal updates.


## Phase 1 — Define the New Host
Run this on a managed machine, or on any machine with `nix` and network access.
Using a managed machine is simpler because the repo and helper commands are
already there.

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
nix run github:axler8r/nixotic#prepare -- <newhost>
```

On a managed machine the zsh wrapper can be used instead:

```bash
New-NixoticHost <newhost>
```

The script:
- Locates or clones `~/.nixotic`.
- Copies `hosts/ambul8r/` as the template.
- Generates a fresh placeholder `networking.hostId`.
- Registers the host in `flake.nix`.
- Runs `nix flake check --no-build`.
- Commits on a new `wip/YYYYMMDD-XXXXXXX` branch.

### Edit the scaffolded config
Review `hosts/<newhost>/configuration.nix` and `hosts/<newhost>/disk.nix` and
adjust them to match the new hardware before pushing:

| File / key                        | Action                                                   |
| --------------------------------- | -------------------------------------------------------- |
| `disk.nix` → `disk.main.device`   | Verify against `lsblk` from the installer ISO            |
| `disk.nix` partition sizes        | Tune for actual disk size                                |
| `services.xserver.videoDrivers`   | Remove NVIDIA entries for Intel/AMD-only hosts           |
| `hardware.nvidia.*` block         | Remove or rewrite for the actual GPU                     |
| `hardware.nvidia.prime.*` bus IDs | Use `lspci` from the new machine; remove if no PRIME     |
| `services.xserver.xkb.layout`     | Set keyboard layout if not `nz`                          |
| `time.timeZone`                   | Update if not `Pacific/Auckland`                         |
| `system.stateVersion`             | Set to the NixOS release being installed                 |
| `users.users.axl.packages`        | Trim or extend for this host's role                      |
| `networking.hostId`               | Placeholder; installer will patch from `/etc/machine-id` |
| `boot.resumeDevice`               | Placeholder; installer will patch from swap UUID         |

### Push to stable
The installer only sees what is already published on `origin/stable`.
Push is always manual:

```bash
cd ~/.nixotic
Update-GitWIPBranchHistory
Complete-GitWIPBranch
git push origin stable
```

If you ran `prepare` on the installer ISO instead of a managed machine, move the
commit to a managed machine first, then push from there:

```bash
# USB
git -C ~/.nixotic format-patch stable..HEAD -o /mnt/usb/
# on managed machine:
git -C ~/.nixotic am /mnt/usb/*.patch
Complete-GitWIPBranch
git push origin stable

# scp
scp -r ~/.nixotic axl@<managed-machine>:/tmp/nixotic-newhost
# on managed machine: cherry-pick or git am, then push
```


## Phase 2 — Boot the Installer ISO
Run this on the new machine. The standard NixOS installer ISO (minimal or
graphical) provides everything needed: `nix`, `git`, `parted`, `cryptsetup`,
and `wpa_supplicant` or `nmtui`.

### Boot the ISO
Write the ISO to a USB stick and boot it on the new machine. Log in as `nixos`
(passwordless sudo is available).

For headless installs, start sshd so the session can be driven remotely:

```bash
sudo systemctl start sshd
sudo passwd nixos
ip a   # note the IP
```

### Bring up the network
Ethernet with DHCP works automatically. Verify:

```bash
curl -fsSI https://github.com >/dev/null && echo ok
```

Wi-Fi (minimal ISO):

```bash
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> set_network 0 ssid "<SSID>"
> set_network 0 psk "<password>"
> enable_network 0
> quit
```

Wi-Fi (graphical ISO): use `nmtui`.

### Collect hardware facts for the new host config
Before running `prepare`, or before finalizing the edited host config, collect
the values you need from the live environment:

```bash
lsblk -o NAME,SIZE,MODEL,TYPE
lspci
ip a
```

At this point the machine is still running only the live ISO. Nothing has been
installed yet.


## Phase 3 — Install From the ISO
Run this on the installer ISO after the host config has been prepared, reviewed,
and pushed to `origin/stable`.

### Enable flakes
The NixOS installer ISO does not enable flakes by default:

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
```

### Verify the target disk
`disko` will destroy the target disk without further prompting. Confirm the
device path matches `disk.main.device` in `hosts/<newhost>/disk.nix`:

```bash
lsblk -o NAME,SIZE,MODEL,TYPE
```

### Run the installer
This is the first and only OS install step in the workflow:

```bash
sudo -E nix run github:axler8r/nixotic#install -- <newhost>
```

`-E` carries `NIX_CONFIG` into the root environment. The installer:

1. Fetches the flake from `origin/stable` on GitHub.
2. Partitions and formats the disk via `disko`.
3. Generates `hardware-configuration.nix` from the live hardware.
4. Patches `boot.resumeDevice` with the swap partition UUID.
5. Patches `networking.hostId` from `/etc/machine-id`.
6. Runs `nixos-install` and prompts for a root password.

When it finishes, reboot. The next boot is the first boot of the installed
system.

> [!NOTE]
> The installer patches happen inside `/tmp/nixotic`, which is discarded on
> reboot. After first boot, those generated values must be copied back into the
> repo checkout on disk.


## Phase 4 — First Boot of the Installed System
Run this on the newly installed host after rebooting out of the installer ISO.
The live installer environment is gone.

### 1. Clone the repository and create a WIP branch
`git` may not be available yet in the base shell environment, so use a
transient `nix-shell`:

```bash
nix-shell -p git --run '
  git clone https://github.com/axler8r/nixotic.git ~/.nixotic
  cd ~/.nixotic
  git checkout stable
  git pull --ff-only origin stable
  git checkout -b "wip/$(date +%Y%m%d-%H%M%S)-firstboot"
'
```

### 2. Persist the hardware configuration
`hardware-configuration.nix` is generated from the live hardware during
install. The repo holds only a placeholder before that point:

```bash
sudo cp /etc/nixos/hardware-configuration.nix \
  ~/.nixotic/hosts/<newhost>/hardware-configuration.nix
```

### 3. Reconcile the installer-patched values
The installer patched `boot.resumeDevice` and `networking.hostId` inside its
temporary checkout under `/tmp/nixotic`. That checkout is gone after reboot, so
update the committed host config to match the running system:

```bash
# Swap UUID
SWAP_UUID="$(blkid -t TYPE=swap -o value -s UUID | head -1)"
sed -i \
  "s|boot\.resumeDevice = \"/dev/disk/by-uuid/[^\"]*\"|boot.resumeDevice = \"/dev/disk/by-uuid/${SWAP_UUID}\"|" \
  ~/.nixotic/hosts/<newhost>/configuration.nix
grep 'boot.resumeDevice' ~/.nixotic/hosts/<newhost>/configuration.nix

# Host ID
HOST_ID="$(head -c 8 /etc/machine-id)"
sed -i \
  "s|networking\.hostId = \"[^\"]*\"|networking.hostId = \"${HOST_ID}\"|" \
  ~/.nixotic/hosts/<newhost>/configuration.nix
grep 'networking.hostId' ~/.nixotic/hosts/<newhost>/configuration.nix
```

### 4. Run the first rebuild
Apply the now-reconciled checkout:

```bash
cd ~/.nixotic
sudo nixos-rebuild switch --flake .#<newhost>
```

This is the only time `nixos-rebuild` is used directly. All later updates use
`nh`:

```bash
nh os switch
```

See [`docs/validation.md`](validation.md) for the full validation pipeline.

### 5. Commit and push the reconciled files
After the first rebuild, commit the real hardware config and the patched
values:

```bash
cd ~/.nixotic
git add hosts/<newhost>/hardware-configuration.nix \
        hosts/<newhost>/configuration.nix
git commit -m "fix(host): persist generated config for <newhost>"
git checkout stable
git merge --ff-only @{-1}
git push origin stable
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
another machine without destroying the OS.


## ZFS Pool Structure
The pool is split into `HOSTDATA` and `USERDATA` so that a machine rebuild —
which wipes root — does not touch personal data. `USERDATA` datasets mount
directly into the home directory and survive reinstalls.

```
dpool                                    mountpoint=none
├── HOSTDATA                             mountpoint=none
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
# hostId is how it detects this. Patched at install time from /etc/machine-id.
networking.hostId = "<patched-by-installer>";

# Hibernate target. Patched at install time from swap partition UUID.
boot.resumeDevice = "/dev/disk/by-uuid/<patched-by-installer>";

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
Edit the relevant `hosts/<hostname>/disk.nix` to add the dataset — disko
creates it on the next fresh install. To add a dataset on a running system without reinstalling:

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
