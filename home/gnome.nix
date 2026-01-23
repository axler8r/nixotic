{ config, pkgs, lib, ... }:

{
  # GNOME Shell extensions and utilities
  home.packages = with pkgs; [
    celluloid
    dconf-editor
    file-roller
    gnome-nettool
    gnome-podcasts
    gnome-power-manager
    gnome-tweaks
    gparted
    mission-center
    shortwave
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.caffeine
    gnomeExtensions.tiling-assistant
  ];

  # Hide unwanted desktop entries
  xdg.desktopEntries.cups = {
    name = "Manage Printing";
    noDisplay = true;
  };
  xdg.desktopEntries."com.brave.Browser" = {
    name = "Brave Web Browser";
    noDisplay = true;
  };

  dconf = {
    enable = true;
    settings = {
      # Window manager preferences
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close,minimize,maximize:";  # macOS-style left side
      };

      # Dock favorites (left to right)
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "brave-browser.desktop"
          "code.desktop"
          "kitty.desktop"
        ];
        # Enable extensions
        disable-user-extensions = false;
        enabled-extensions = [
          "clipboard-indicator@tudmotu.com"
          "caffeine@patapon.info"
          "tiling-assistant@ubuntu.com"
        ];
      };

      # App folder configuration - minimal with few apps
      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "CommandLine"
          "Handy"
          "Media"
          "System"
          "Utilities"
        ];
      };

      # Command Line Tools folder
      "org/gnome/desktop/app-folders/folders/CommandLine" = {
        name = "Command Line Tools";
        apps = [
          "Helix.desktop"
          "htop.desktop"
          "nvim.desktop"
          "ranger.desktop"
        ];
      };

      # Utilities folder
      "org/gnome/desktop/app-folders/folders/Utilities" = {
        name = "Utilities";
        apps = [
          "org.gnome.seahorse.Application.desktop"
          "org.gnome.tweaks.desktop"
          "org.gnome.Settings.desktop"
        ];
      };

      # Handy folder
      "org/gnome/desktop/app-folders/folders/Handy" = {
        name = "Handy";
        apps = [
          "org.gnome.Calculator.desktop"
          "org.gnome.Calendar.desktop"
          "org.gnome.Characters.desktop"
          "org.gnome.FileRoller.desktop"
          "org.gnome.Papers.desktop"
          "org.gnome.clocks.desktop"
          "org.gnome.Extensions.desktop"
          "org.gnome.font-viewer.desktop"
          "org.gnome.Maps.desktop"
          "org.gnome.SimpleScan.desktop"
          "org.gnome.TextEditor.desktop"
          "org.gnome.Weather.desktop"
        ];
      };

      # Media folder
      "org/gnome/desktop/app-folders/folders/Media" = {
        name = "Media";
        apps = [
          "de.haeckerfelix.Shortwave.desktop"
          "io.github.celluloid_player.Celluloid.desktop"
          "org.gnome.Decibels.desktop"
          "org.gnome.Loupe.desktop"
          "org.gnome.Music.desktop"
          "org.gnome.Podcasts.desktop"
          "org.gnome.Showtime.desktop"
          "mpv.desktop"
        ];
      };
      # System folder
      "org/gnome/desktop/app-folders/folders/System" = {
        name = "System";
        apps = [
          "ca.desrt.dconf-editor.desktop"
          "gnome-nettool.desktop"
          "gparted.desktop"
          "io.missioncenter.MissionCenter.desktop"
          "org.gnome.baobab.desktop"
          "org.gnome.Console.desktop"
          "org.gnome.DiskUtility.desktop"
          "org.gnome.Logs.desktop"
          "org.gnome.PowerStats.desktop"
          "org.gnome.SystemMonitor.desktop"
        ];
      };
      # Keyboard input settings
      "org/gnome/desktop/input-sources" = {
        xkb-options = [ "compose:ralt" "caps:ctrl_modifier" ];
      };

      # Remap IBus unicode hotkey to Ctrl+Alt+U (frees Ctrl+Shift+U for Kitty)
      "org/freedesktop/ibus/panel/emoji" = {
        unicode-hotkey = [ "<Control><Alt>u" ];
      };

      # GNOME Console - use Stylix theme colors
      "org/gnome/Console" = {
        use-system-font = true;
        theme = "auto";  # Follows light/dark preference
      };
    };
  };
}
