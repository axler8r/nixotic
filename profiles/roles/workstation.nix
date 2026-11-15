# GNOME workstation role: everything a workstation needs beyond base.nix.
# Injected by mkHost (role = "workstation"); hosts do not import it.
# Hardware quirks (GPU driver, resume device, extra ZFS pools) stay in the
# host's own configuration.nix or a profiles/hardware module.
{ pkgs, ... }:

{
  imports = [ ./base.nix ];

  # Network
  networking.networkmanager.enable = true;

  # Service
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.openssh.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.printing.enable = true;
  services.pulseaudio.enable = false;
  services.xserver.enable = true;
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };

  # Prevent GDM from suspending the system while showing the login screen
  # This fixes the double-suspend issue after waking from sleep
  programs.dconf.profiles.gdm.databases = [
    {
      settings = {
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "nothing";
        };
      };
    }
  ];

  # Environment
  # Exclude GNOME defaults not used in 90 days (docs/tooling-tiers.md)
  environment.gnome.excludePackages = with pkgs; [
    baobab # disk usage analyser
    cheese # webcam
    decibels # audio player
    epiphany # web browser
    geary # email client
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-connections # remote desktop client
    gnome-console # replaced by gnome-terminal
    gnome-contacts
    gnome-disk-utility # disks
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-system-monitor
    gnome-tour
    gnome-weather
    seahorse # passwords and keys
    showtime # video player
    simple-scan # document scanner
    snapshot # camera
    yelp # help viewer
  ];
  environment.systemPackages = with pkgs; [
    cryptsetup # LUKS encryption for ax vault
  ];
  fonts.packages = with pkgs; [
    cascadia-code
  ];

  users.users.axl = {
    extraGroups = [
      "networkmanager"
      "docker"
    ];
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/var/lib/docker";
      storage-driver = "zfs";
    };
  };

  security.rtkit.enable = true;
}
