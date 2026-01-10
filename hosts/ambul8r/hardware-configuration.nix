# Placeholder hardware configuration for ambul8r (laptop)
# 
# REPLACE THIS FILE when deploying to actual hardware:
#   nixos-generate-config --show-hardware-config > ~/.nixotic/hosts/ambul8r/hardware-configuration.nix
#
# This placeholder allows the flake to evaluate purely for CI/validation.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Placeholder values - will be replaced by actual hardware scan
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Root filesystem - MUST be replaced with actual UUIDs
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  swapDevices = [ ];

  # Laptop-specific
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
