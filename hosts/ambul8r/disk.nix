{ lib, ... }:

let
  # Flip to `true` at next reinstall to host /nix on ZFS.
  # Keep `false` on the running system — disko-generated
  # fileSystems entries would otherwise try to mount a
  # dataset that does not exist.
  enableNixOnZfs = false;
in
{
  # Partitioning declaration only — hardware-configuration.nix owns the
  # fileSystems/swapDevices of the running system.
  disko.enableConfig = false;

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "5G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
            root = {
              size = "150G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
            swap = {
              size = "32G";
              type = "8200";
              content = {
                type = "swap";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      dpool = {
        type = "zpool";
        options = {
          ashift = "12";
        };
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          mountpoint = "none";
        };
        # When adding a dataset with a mountpoint, add a matching tmpfiles rule
        # in configuration.nix → systemd.tmpfiles.rules to set ownership on boot.
        datasets = {
          HOSTDATA = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "HOSTDATA/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "HOSTDATA/var/lib" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "HOSTDATA/var/lib/docker" = {
            type = "zfs_fs";
            options.mountpoint = "/var/lib/docker";
          };
          USERDATA = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "USERDATA/home" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "USERDATA/home/axl" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "USERDATA/home/axl/Documents" = {
            type = "zfs_fs";
            options.mountpoint = "/home/axl/Documents";
          };
          "USERDATA/home/axl/Downloads" = {
            type = "zfs_fs";
            options.mountpoint = "/home/axl/Downloads";
          };
          "USERDATA/home/axl/Media" = {
            type = "zfs_fs";
            options.mountpoint = "/home/axl/Media";
          };
          "USERDATA/home/axl/Projects" = {
            type = "zfs_fs";
            options.mountpoint = "/home/axl/Projects";
          };
          "USERDATA/home/axl/Projects/AxlER8R" = {
            type = "zfs_fs";
          };
          "USERDATA/home/axl/Projects/GitHub" = {
            type = "zfs_fs";
          };
          "USERDATA/home/axl/Projects/GitLab" = {
            type = "zfs_fs";
          };
          "USERDATA/home/axl/Projects/Sandbox" = {
            type = "zfs_fs";
          };
          "USERDATA/home/axl/Vaults" = {
            type = "zfs_fs";
            options.mountpoint = "/home/axl/Vaults";
          };
        } // lib.optionalAttrs enableNixOnZfs {
          "HOSTDATA/nix" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/nix";
              atime = "off";
            };
          };
        };
      };
    };
  };
}
