# ML Workstation configuration (infer8r)
# TODO: Set up when deploying to ML workstation
#
# Quick start:
# 1. Boot NixOS installer on workstation
# 2. Copy hardware-configuration.nix:
#    cp /etc/nixos/hardware-configuration.nix ~/.nixotic/hosts/infer8r/
# 3. Customise this file for ML workstation needs
# 4. Rebuild: sudo nixos-rebuild switch --flake ~/.nixotic#infer8r --impure

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader - adjust for your system
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "infer8r";
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
    extraGroups = [ "networkmanager" "wheel" "docker" ];
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

  # Docker for ML containers
  virtualisation.docker.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    htop
    wget
  ];

  # TODO: Add ML workstation-specific configuration:
  # - NVIDIA drivers and CUDA
  # - nvidia-container-toolkit for Docker GPU access
  # - Large swap or zram for big models
  # - SSH server for remote access
  # - Jupyter/JupyterLab system service

  system.stateVersion = "25.11";
}
