{ ... }:

{
  # No ZFS here, so let disko own the fileSystems: it derives
  # fileSystems."/" and "/boot" from the mountpoints below. This is what
  # satisfies the root-filesystem assertion during a fresh nixos-anywhere
  # install, where nixos-generate-config runs before the disk is partitioned
  # and therefore cannot emit fileSystems itself.

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
