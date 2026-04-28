{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "1";  # 80x50 - readable on 4K 16"
  boot.loader.efi.canTouchEfiVariables = true;

  # Hibernation support
  boot.resumeDevice = "/dev/disk/by-uuid/79350aff-370a-4bf1-badd-c0863589bdf6";

  # ZFS and NFS support
  boot.supportedFilesystems = [ "zfs" "nfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "dpool" ];
  networking.hostId = "001421c4";  # Required for ZFS - from: head -c 8 /etc/machine-id

  networking.hostName = "ambul8r";
  networking.networkmanager.enable = true;

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
  services.xserver.videoDrivers = [ "nvidia" ];
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Prevent GDM from suspending the system while showing the login screen
  # This fixes the double-suspend issue after waking from sleep
  programs.dconf.profiles.gdm.databases = [{
    settings = {
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };
    };
  }];

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

  # NVIDIA GPU support (hybrid graphics with PRIME)
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;       # Better battery life
    powerManagement.finegrained = true;  # Turn off GPU when not in use
    open = false;                        # Use proprietary driver
    nvidiaSettings = true;               # NVIDIA Settings app
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Adds `nvidia-offload` wrapper
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Disabled on the laptop: the CDI generator can fail during activation when
  # the dGPU driver is not loaded under PRIME offload/power saving.
  hardware.nvidia-container-toolkit.enable = false;

  # Exclude GNOME bloat
  environment.gnome.excludePackages = with pkgs; [
    cheese         # webcam
    epiphany       # web browser
    geary          # email client
    gnome-console  # replaced by gnome-terminal
    gnome-contacts
    gnome-tour
    snapshot       # camera
    yelp           # help viewer
  ];

  security.rtkit.enable = true;
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
  '';

  users.users.axl = {
    isNormalUser = true;
    description = "Axl";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
      # Browsers
      brave
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
  fonts.packages = with pkgs; [ cascadia-code fira-code jetbrains-mono ];
  programs.nix-ld.enable = true;  # Run non-NixOS binaries
  programs.zsh.enable = true;
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/var/lib/docker";
      storage-driver = "zfs";
    };
  };

  systemd.services.docker = {
    after = [ "zfs-import-dpool.service" ];
    requires = [ "zfs-import-dpool.service" ];
    path = [ pkgs.zfs ];
  };

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # system tools
    cryptsetup  # LUKS encryption for vault functions
    file
    htop
    iftop
    iotop
    nethogs
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

  systemd.tmpfiles.rules = [
    "d /home/axl/Documents                0755 axl users -"
    "d /home/axl/Downloads                0755 axl users -"
    "d /home/axl/Media                    0755 axl users -"
    "d /home/axl/Projects                 0755 axl users -"
    "d /home/axl/Projects/AxlER8R         0755 axl users -"
    "d /home/axl/Projects/GitHub          0755 axl users -"
    "d /home/axl/Projects/GitLab          0755 axl users -"
    "d /home/axl/Projects/Sandbox         0755 axl users -"
    "d /home/axl/Vaults                   0755 axl users -"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
