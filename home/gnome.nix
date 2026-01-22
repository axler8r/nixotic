{ config, pkgs, lib, ... }:

{
  # GNOME Shell extensions and utilities
  home.packages = with pkgs; [
    gnome-tweaks
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
          "Utilities"
          "Media"
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
          "org.gnome.Calculator.desktop"
          "org.gnome.Evince.desktop"
          "org.gnome.FileRoller.desktop"
          "org.gnome.Loupe.desktop"
          "org.gnome.seahorse.Application.desktop"
          "org.gnome.tweaks.desktop"
          "org.gnome.Settings.desktop"
        ];
      };

      # Media folder
      "org/gnome/desktop/app-folders/folders/Media" = {
        name = "Media";
        apps = [
          "mpv.desktop"
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
    };
  };
}
