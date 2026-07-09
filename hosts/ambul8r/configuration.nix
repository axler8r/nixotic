{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./disk.nix
      ../common/workstation.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "1";  # 80x50 - readable on 4K 16"
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernation support
  boot.resumeDevice = "/dev/disk/by-uuid/79350aff-370a-4bf1-badd-c0863589bdf6";

  # ZFS and NFS support (legacy layout — predates hosts/common/zfs-root.nix)
  boot.supportedFilesystems = [ "zfs" "nfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "dpool" ];
  networking.hostId = "001421c4";  # Required for ZFS — random, permanent per host

  networking.hostName = "ambul8r";

  services.xserver.videoDrivers = [ "nvidia" ];
  services.rpcbind.enable = true;

  # NVIDIA GPU support (hybrid graphics with PRIME)
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;       # Better battery life
    powerManagement.finegrained = true;  # Turn off GPU when not in use
    open = false;                        # Use proprietary driver
    nvidiaSettings = true;               # NVIDIA Settings app
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Adds `nvidia-offload` wrapper
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Disabled on the laptop: the CDI generator can fail during activation when
  # the dGPU driver is not loaded under PRIME offload/power saving.
  hardware.nvidia-container-toolkit.enable = false;

  # Docker data lives on dpool; order the daemon after the pool import.
  systemd.services.docker = {
    after = [ "zfs-import-dpool.service" ];
    requires = [ "zfs-import-dpool.service" ];
    path = [ pkgs.zfs ];
  };

  # ZFS services
  services.zfs = {
    autoScrub.enable = true;           # Monthly scrub for data integrity
    autoScrub.interval = "monthly";
    trim.enable = true;                # TRIM for SSDs
  };

  systemd.tmpfiles.rules = [
    "d /home/axl/Documents                0755 axl users -"
    "d /home/axl/Downloads                0755 axl users -"
    "d /home/axl/Media                    0755 axl users -"
    "d /home/axl/Projects                 0755 axl users -"
    "d /home/axl/Projects/AxlER8R         0755 axl users -"
    "d /home/axl/Projects/GitHub          0755 axl users -"
    "d /home/axl/Projects/GitLab          0755 axl users -"
    "d /home/axl/Projects/Sandbox         0755 axl users -"
    "d /home/axl/Vaults                   0755 axl users -"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It’s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
