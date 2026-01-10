# Laptop configuration (ambul8r)
# TODO: Set up when deploying to laptop
#
# Quick start:
# 1. Boot NixOS installer on laptop
# 2. Copy hardware-configuration.nix: 
#    cp /etc/nixos/hardware-configuration.nix ~/.nixotic/hosts/ambul8r/
# 3. Customise this file for laptop-specific needs
# 4. Rebuild: sudo nixos-rebuild switch --flake ~/.nixotic#ambul8r --impure

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader - adjust for your laptop
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ambul8r";
  networking.networkmanager.enable = true;

  # Time zone - adjust as needed
  time.timeZone = "Pacific/Auckland";

  # Locale
  i18n.defaultLocale = "en_NZ.UTF-8";

  # Desktop environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # User account
  users.users.axl = {
    isNormalUser = true;
    description = "Axl";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      brave
      ungoogled-chromium
    ];
  };

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 21d";
  };

  # Shell configuration
  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;

  # Fonts
  fonts.packages = with pkgs; [ cascadia-code fira-code jetbrains-mono ];

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    htop
    wget
  ];

  # TODO: Add laptop-specific configuration:
  # - Power management (TLP, powertop)
  # - Touchpad settings
  # - Battery optimisation
  # - Lid switch behaviour

  system.stateVersion = "25.11";
}
