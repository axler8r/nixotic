# Shared configuration for every nixotic host, workstation or server.
# WSL-safe: no bootloader, disk, or ZFS assumptions — those live in the
# host's own configuration.nix or in zfs-root.nix.
{ pkgs, ... }:

{
  time.timeZone = "Pacific/Auckland";

  i18n.defaultLocale = "en_NZ.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
    LC_MONETARY = "en_NZ.UTF-8";
    LC_NAME = "en_NZ.UTF-8";
    LC_NUMERIC = "en_NZ.UTF-8";
    LC_PAPER = "en_NZ.UTF-8";
    LC_TELEPHONE = "en_NZ.UTF-8";
    LC_TIME = "en_DK.UTF-8";
  };

  users.users.axl = {
    isNormalUser = true;
    description = "Axl";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtuDV/jvCTj5Hxs55fQFJDZR1Jo+v9YdLzUPXJ918Pr axl@ambul8r"
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Build performance
    max-jobs = "auto";
    cores = 0;

    # Additional binary caches
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
  programs.nix-ld.enable = true;  # Run non-NixOS binaries

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
  '';

  environment.systemPackages = with pkgs; [
    file
  ];
}
