{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cre8r";

  time.timeZone = "Pacific/Auckland";

  i18n.defaultLocale = "en_NZ.UTF-8";

  users.users.axl = {
    isNormalUser = true;
    description = "Axl";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    # Console fallback for the Proxmox VM console; change after first login.
    initialPassword = "cre8r-initial";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtuDV/jvCTj5Hxs55fQFJDZR1Jo+v9YdLzUPXJ918Pr axl@ambul8r"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Proxmox guest integration (clean shutdown, IP reporting in the UI).
  services.qemuGuest.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    max-jobs = "auto";
    cores = 0;

    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
    persistent = true;
  };

  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    file
  ];

  system.stateVersion = "25.11";
}
