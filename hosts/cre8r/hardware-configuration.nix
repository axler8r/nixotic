# Placeholder hardware configuration for cre8r
#
# Overwritten automatically during install by:
#   nixos-anywhere --generate-hardware-config nixos-generate-config \
#     hosts/cre8r/hardware-configuration.nix
#
# This placeholder allows the flake to evaluate before the host is installed.

{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "virtio_pci" "virtio_scsi" "virtio_blk" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Dummy entries so the flake evaluates pre-install (NixOS asserts a root
  # fileSystem exists). The generated file replaces these with the real
  # by-uuid entries from the disko-mounted layout.
  fileSystems."/" = {
    device = "/dev/disk/by-partlabel/disk-main-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/disk-main-ESP";
    fsType = "vfat";
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
