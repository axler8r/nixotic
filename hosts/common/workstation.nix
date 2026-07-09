# GNOME workstation role: everything a workstation needs beyond base.nix.
# Hardware quirks (GPU driver, resume device, extra ZFS pools) stay in the
# host's own configuration.nix.
{ pkgs, ... }:

{
  imports = [ ./base.nix ];

  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };
  services.xserver.excludePackages = [ pkgs.xterm ];
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

  services.printing.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  users.users.axl = {
    extraGroups = [ "networkmanager" "docker" ];
    packages = with pkgs; [
      # Browsers
      brave
    ];
  };

  fonts.packages = with pkgs; [ cascadia-code fira-code jetbrains-mono ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/var/lib/docker";
      storage-driver = "zfs";
    };
  };

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # system tools
    cryptsetup  # LUKS encryption for vault functions
    htop
    iftop
    iotop
    nethogs
    net-tools
    plocate
  ];
}
