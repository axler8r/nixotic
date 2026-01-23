{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernation support
  boot.resumeDevice = "/dev/disk/by-uuid/79350aff-370a-4bf1-badd-c0863589bdf6";

  # ZFS and NFS support
  boot.supportedFilesystems = [ "zfs" "nfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "001421c4";  # Required for ZFS - from: head -c 8 /etc/machine-id

  networking.hostName = "ambul8r";
  networking.networkmanager.enable = true;
  networking.wireless.enable = true;

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
  services.xserver.excludePackages = [ pkgs.xterm ];
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
  services.rpcbind.enable = true;
  # services.xserver.libinput.enable = true; # Enable touchpad support

  # Exclude GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    cheese         # webcam
    epiphany       # web browser
    geary          # email client
    gnome-console
    gnome-contacts
    gnome-tour
    snapshot       # camera
    yelp           # help viewer
  ];

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
    ];
  };


  # User required system features
  ####################################################################
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

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
    # system tools
    clamav
    file
    htop
    net-tools
    plocate
  ];

  services.openssh.enable = true;

  # ZFS services
  services.zfs = {
    autoScrub.enable = true;           # Monthly scrub for data integrity
    autoScrub.interval = "monthly";
    trim.enable = true;                # TRIM for SSDs
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
