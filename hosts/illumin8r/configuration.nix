{ pkgs, inputs, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl.enable = true;
  wsl.defaultUser = "axl";

  networking.hostName = "illumin8r";

  time.timeZone = "Pacific/Auckland";

  i18n.defaultLocale = "en_NZ.UTF-8";

  users.users.axl = {
    isNormalUser = true;
    description = "Axl";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
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
  programs.nix-ld.enable = true;

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      storage-driver = "overlay2";
    };
  };

  environment.systemPackages = with pkgs; [
    file
  ];

  system.stateVersion = "25.11";
}
