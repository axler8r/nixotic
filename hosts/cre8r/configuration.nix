{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../common/base.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cre8r";

  # Console fallback for the Proxmox VM console; change after first login.
  users.users.axl.initialPassword = "cre8r-initial";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Proxmox guest integration (clean shutdown, IP reporting in the UI).
  services.qemuGuest.enable = true;

  system.stateVersion = "25.11";
}
