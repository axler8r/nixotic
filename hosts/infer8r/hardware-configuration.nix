# Placeholder hardware configuration for infer8r (ML workstation)
# 
# REPLACE THIS FILE when deploying to actual hardware:
#   nixos-generate-config --show-hardware-config > ~/.nixotic/hosts/infer8r/hardware-configuration.nix
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
  boot.kernelModules = [ "kvm-amd" ];  # Assuming AMD for ML workstation
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

  # ML workstation likely has dedicated GPU
  # hardware.nvidia.enable = true;  # Uncomment when deploying

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
