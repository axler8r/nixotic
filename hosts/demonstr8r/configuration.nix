{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "demonstr8r";
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;

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
    LC_TIME = "en_NZ.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # services.xserver.libinput.enable = true; # Enable touchpad support

  security.rtkit.enable = true;

  ####################################################################
  # User configuration
  ####################################################################
  users.users.axl = {
    isNormalUser = true;
    description = "Axl";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;

    # User-specific packages that require GNOME integration
    ##################################################################
    packages = with pkgs; [
      # Browsers
      brave
      ungoogled-chromium
    ];
  };


  # User required system features
  ####################################################################
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 21d";
    persistent = true;
  };
  
  environment.shells = with pkgs; [ zsh ];
  fonts.packages = with pkgs; [ cascadia-code fira-code jetbrains-mono ];
  programs.nix-ld.enable = true;  # Run non-NixOS binaries
  programs.zsh.enable = true;
  virtualisation.docker.enable = true;


  # Packages avilable to all users
  ####################################################################
  environment.systemPackages = with pkgs; [
    # editor
    neovim
    # system tools
    clamav
    file
    htop
    lsof
    net-tools
    p7zip
    plocate
    pv
    socat
    tree
    wget
  ];

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default settings for
  # stateful data, like file locations and database versions on your system were
  # taken. It's perfectly fine and recommended to leave this value at the
  # release version of the first install of this system.  Before changing this
  # value read the documentation for this option (e.g. man configuration.nix or
  # on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
