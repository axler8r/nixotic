# ZFS Configuration
ZFS setup on ambul8r (laptop) with hibernation support.


## Disk Layout
| Partition |  Size | Type | Purpose     |
| --------- | ----: | ---- | ----------- |
| nvme0n1p1 |    5G | vfat | /boot (EFI) |
| nvme0n1p2 |  150G | ext4 | / (root)    |
| nvme0n1p3 |   32G | swap | Hibernation |
| nvme0n1p4 | ~766G | ZFS  | dpool       |


## ZFS Pool Structure
[files/zsh/functions/New-ZfsLayout](files/zsh/functions/New-ZfsLayout) recreates the dataset hierarchy and ownership described below.

```
dpool                                    mountpoint=none
└── USERDATA                             mountpoint=none
    └── home                             mountpoint=none
        └── axl                          mountpoint=none
            ├── Documents                /home/axl/Documents
            ├── Downloads                /home/axl/Downloads
            ├── Media                    /home/axl/Media
            ├── Projects                 /home/axl/Projects
            │   ├── AxlER8R              /home/axl/Projects/AxlER8R
            │   ├── GitHub               /home/axl/Projects/GitHub
            │   ├── GitLab               /home/axl/Projects/GitLab
            │   └── Sandbox              /home/axl/Projects/Sandbox
            └── Vaults                   /home/axl/Vaults
```


## NixOS Configuration

### Required Settings
```nix
# configuration.nix
boot.supportedFilesystems = [ "zfs" ];
boot.zfs.forceImportRoot = false;
networking.hostId = "001421c4";  # head -c 8 /etc/machine-id

# Hibernation
boot.resumeDevice = "/dev/disk/by-uuid/<swap-uuid>";

# ZFS services
services.zfs = {
  autoScrub.enable = true;
  autoScrub.interval = "monthly";
  trim.enable = true;
};
```

### Swap for Hibernation
```nix
# hardware-configuration.nix
swapDevices = [
  { device = "/dev/disk/by-uuid/<swap-uuid>"; }
];
```


## Initial Setup Commands
```bash
# Create partitions (using fdisk)
sudo fdisk /dev/nvme0n1
# n → +32G (swap), n → remaining (ZFS), t → 3 → 19 (swap type), w

# Set up swap
sudo mkswap /dev/nvme0n1p3
sudo blkid /dev/nvme0n1p3  # Get UUID for config

# Apply NixOS config and reboot (loads ZFS modules)
nh os switch
sudo reboot

# Create ZFS pool
sudo zpool create -o ashift=12 -O compression=zstd -O acltype=posixacl \
  -O xattr=sa -O mountpoint=none dpool /dev/nvme0n1p4

# Create dataset hierarchy
sudo zfs create -o mountpoint=none dpool/USERDATA
sudo zfs create -o mountpoint=none dpool/USERDATA/home
sudo zfs create -o mountpoint=none dpool/USERDATA/home/axl
sudo zfs create -o mountpoint=/home/axl/Documents dpool/USERDATA/home/axl/Documents
sudo zfs create -o mountpoint=/home/axl/Downloads dpool/USERDATA/home/axl/Downloads
sudo zfs create -o mountpoint=/home/axl/Media dpool/USERDATA/home/axl/Media
sudo zfs create -o mountpoint=/home/axl/Projects dpool/USERDATA/home/axl/Projects
sudo zfs create dpool/USERDATA/home/axl/Projects/AxlER8R
sudo zfs create dpool/USERDATA/home/axl/Projects/GitHub
sudo zfs create dpool/USERDATA/home/axl/Projects/GitLab
sudo zfs create dpool/USERDATA/home/axl/Projects/Sandbox
sudo zfs create -o mountpoint=/home/axl/Vaults dpool/USERDATA/home/axl/Vaults

# Set ownership
sudo chown -R axl:users /home/axl/{Documents,Downloads,Media,Projects,Vaults}
```


## Common Commands
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


## Adding New Datasets
```bash
# New project dataset (inherits mountpoint from parent)
sudo zfs create dpool/USERDATA/home/axl/Projects/NewProject
sudo chown axl:users /home/axl/Projects/NewProject

# New top-level dataset (explicit mountpoint)
sudo zfs create -o mountpoint=/home/axl/NewFolder dpool/USERDATA/home/axl/NewFolder
sudo chown axl:users /home/axl/NewFolder
```
