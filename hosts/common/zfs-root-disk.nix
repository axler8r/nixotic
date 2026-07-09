# Parameterised ZFS-on-root disko layout shared by all new hosts.
#
#   import ../common/zfs-root-disk.nix {
#     device      = "/dev/nvme0n1";
#     swap        = "zram";       # "zram" (fixed) | "hibernate" (portable)
#     swapSizeGiB = null;         # required when swap = "hibernate"
#   }
#
# No filesystem encryption: every dataset is plain ZFS, so the host boots
# fully unattended and home just mounts. Per-secret encryption is on demand
# with New-Vault (LUKS vault files under ~/Vaults), not at this layer.
{ device
, swap ? "zram"
, swapSizeGiB ? null
}:

assert swap == "zram" || swap == "hibernate";
assert (swap == "hibernate") -> (swapSizeGiB != null);

{ lib, ... }:

let
  hibernate = swap == "hibernate";

  userChild = mountpoint: {
    type = "zfs_fs";
    options.mountpoint = mountpoint;
  };
in
{
  disko.devices = {
    disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions =
          {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
          }
          // lib.optionalAttrs hibernate {
            swap = {
              size = "${toString swapSizeGiB}G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          }
          // {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options.ashift = "12";
      rootFsOptions = {
        compression = "zstd";
        acltype = "posixacl";
        xattr = "sa";
        mountpoint = "none";
      };
      datasets = {
        # Boot-critical, unencrypted datasets are NixOS-mounted: disko emits a
        # config.fileSystems.<top-level mountpoint> entry only when the
        # top-level `mountpoint` is set, and `options.mountpoint = "legacy"`
        # hands the mount to NixOS/systemd (not ZFS auto-mount).
        "ROOT" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "ROOT/nixos" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };

        "HOSTDATA" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "HOSTDATA/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options = { mountpoint = "legacy"; atime = "off"; };
        };
        "HOSTDATA/var" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "HOSTDATA/var/lib" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "HOSTDATA/var/lib/docker" = {
          type = "zfs_fs";
          mountpoint = "/var/lib/docker";
          options.mountpoint = "legacy";
        };

        "USERDATA" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "USERDATA/home" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "USERDATA/home/axl" = { type = "zfs_fs"; options.mountpoint = "none"; };
        "USERDATA/home/axl/Documents" = userChild "/home/axl/Documents";
        "USERDATA/home/axl/Downloads" = userChild "/home/axl/Downloads";
        "USERDATA/home/axl/Media" = userChild "/home/axl/Media";
        "USERDATA/home/axl/Projects" = userChild "/home/axl/Projects";
        "USERDATA/home/axl/Projects/AxlER8R" = userChild "/home/axl/Projects/AxlER8R";
        "USERDATA/home/axl/Projects/GitHub" = userChild "/home/axl/Projects/GitHub";
        "USERDATA/home/axl/Projects/GitLab" = userChild "/home/axl/Projects/GitLab";
        "USERDATA/home/axl/Projects/Sandbox" = userChild "/home/axl/Projects/Sandbox";
        "USERDATA/home/axl/Vaults" = userChild "/home/axl/Vaults";
      };
    };
  };
}
