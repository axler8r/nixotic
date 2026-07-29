{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../common/workstation.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "1";
  boot.loader.systemd-boot.enable = true;
  boot.resumeDevice = "/dev/disk/by-uuid/79350aff-370a-4bf1-badd-c0863589bdf6"; # Enable hybernation
  boot.supportedFilesystems = [
    "zfs"
    "nfs"
  ];
  boot.zfs.extraPools = [ "dpool" ];
  boot.zfs.forceImportRoot = false;

  networking.hostId = "001421c4"; # Required for ZFS — random, permanent per host
  networking.hostName = "ambul8r";

  services.rpcbind.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.zfs = {
    autoScrub.enable = true; # Monthly scrub for data integrity
    autoScrub.interval = "monthly";
    trim.enable = true; # TRIM for SSDs
  };

  systemd.services.docker = {
    after = [ "zfs-import-dpool.service" ];
    requires = [ "zfs-import-dpool.service" ];
    path = [ pkgs.zfs ];
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

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true; # NVIDIA Settings app
    open = false; # Use proprietary driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true; # Better battery life
    powerManagement.finegrained = true; # Turn off GPU when not in use
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true; # Adds `nvidia-offload` wrapper
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  hardware.nvidia-container-toolkit.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It’s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
