{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../../profiles/platform/proxmox-vm.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cre8r";

  # Console fallback for the Proxmox VM console; change after first login.
  users.users.axl.initialPassword = "Ch4ng3Me!";

  system.stateVersion = "25.11";
}
