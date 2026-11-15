{
  config,
  pkgs,
  lib,
  ...
}:

{
  # GNOME Shell extensions and utilities
  home.packages = with pkgs; [
    brave
    gnome-terminal
    ungoogled-chromium
    meld
    obsidian
    protonmail-desktop
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.caffeine
    gnomeExtensions.dash-to-dock
    gnomeExtensions.date-menu-formatter
    gnomeExtensions.draw-on-gnome
    gnomeExtensions.just-perfection
    gnomeExtensions.tiling-assistant
    gnomeExtensions.tiling-shell
    gnomeExtensions.vitals
  ];

  # Hide unwanted desktop entries
  xdg.desktopEntries.cups = {
    name = "Manage Printing";
    noDisplay = true;
  };
  xdg.desktopEntries.nixos-manual = {
    name = "NixOS Manual";
    noDisplay = true;
  };

  # XDG user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = false;
    desktop = null;
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Media/Music";
    pictures = "${config.home.homeDirectory}/Media/Pictures";
    publicShare = null;
    templates = null;
    videos = "${config.home.homeDirectory}/Media/Videos";
  };

  # Custom folder icons
  home.activation.setFolderIcons = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    [[ -d $HOME/.nixotic ]] && ${pkgs.glib}/bin/gio set $HOME/.nixotic metadata::custom-icon-name folder-darkcyan-important
    [[ -d $HOME/Documents/Books ]] && ${pkgs.glib}/bin/gio set $HOME/Documents/Books metadata::custom-icon-name folder-pink-books
    [[ -d $HOME/Documents/Obsidian ]] && ${pkgs.glib}/bin/gio set $HOME/Documents/Obsidian metadata::custom-icon-name folder-indigo-obsidian
    [[ -d $HOME/Downloads ]] && ${pkgs.glib}/bin/gio set $HOME/Downloads metadata::custom-icon-name folder-green-download
    [[ -d $HOME/Projects ]] && ${pkgs.glib}/bin/gio set $HOME/Projects metadata::custom-icon-name folder-orange-development
    [[ -d $HOME/Projects/AxlER8R ]] && ${pkgs.glib}/bin/gio set $HOME/Projects/AxlER8R metadata::custom-icon-name folder-green-meocloud
    [[ -d $HOME/Projects/GitHub ]] && ${pkgs.glib}/bin/gio set $HOME/Projects/GitHub metadata::custom-icon-name folder-grey-github
    [[ -d $HOME/Projects/GitLab ]] && ${pkgs.glib}/bin/gio set $HOME/Projects/GitLab metadata::custom-icon-name folder-deeporange-gitlabb
    [[ -d $HOME/Projects/Sandbox ]] && ${pkgs.glib}/bin/gio set $HOME/Projects/Sandbox metadata::custom-icon-name folder-yellow-recent
    [[ -d $HOME/Vaults ]] && ${pkgs.glib}/bin/gio set $HOME/Vaults metadata::custom-icon-name folder-red-locked
  '';

  dconf = {
    enable = true;
    settings = {
      # Window manager preferences
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close,minimize,maximize:"; # macOS-style left side
      };

      # Screen blank and lock settings
      "org/gnome/desktop/session" = {
        idle-delay = 600; # Blank after 10 minutes (in seconds)
      };
      "org/gnome/settings-daemon/plugins/power" = {
        idle-dim = true; # Dim screen before blanking
      };
      "org/gnome/desktop/screensaver" = {
        lock-delay = 300; # Lock 5 min after blank (15 min total)
      };

      # Dock favorites (left to right)
      "org/gnome/shell" = {
        favorite-apps = [
          "org.gnome.Nautilus.desktop"
          "brave-browser.desktop"
          "proton-mail.desktop"
          "md.obsidian.Obsidian.desktop"
          "org.gnome.Meld.desktop"
          "code.desktop"
          "kitty.desktop"
        ];
        # Enable extensions
        disable-user-extensions = false;
        enabled-extensions = [
          "clipboard-indicator@tudmotu.com"
          "caffeine@patapon.info"
          "dash-to-dock@micxgx.gmail.com"
          "date-menu-formatter@marcinjakubowski.github.com"
          "draw-on-gnome@daveprowse.github.io"
          "just-perfection-desktop@just-perfection"
          "tiling-assistant@ubuntu.com"
          "tilingshell@ferrarodomenico.com"
          "Vitals@CoreCoding.com"
        ];
      };

      # Alt+Tab switches apps on current workspace only
      "org/gnome/shell/app-switcher" = {
        current-workspace-only = true;
      };

      # Dash to Dock configuration
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position = "BOTTOM";
        dock-fixed = false;
        autohide = true;
        intellihide = true;
        show-trash = false;
        show-mounts = false;
      };

      # Vitals - system stats on right side of panel
      "org/gnome/shell/extensions/vitals" = {
        position-in-panel = 2; # 0=left, 1=center, 2=right
        hot-sensors = [
          "_processor_usage_"
          "_memory_usage_"
          "_storage_read_rate_"
          "_storage_write_rate_"
          "__network-rx_max__"
          "__network-tx_max__"
          "__temperature_avg__"
        ];
      };

      # Date Menu Formatter
      "org/gnome/shell/extensions/date-menu-formatter" = {
        pattern = "'It is' HH:mm 'on' EEEE, MMMM d, yyyy";
      };

      # App folder configuration - minimal with few apps
      "org/gnome/desktop/app-folders" = {
        folder-children = [
          "Assist"
          "Browse"
          "Command"
          "Entertain"
        ];
      };

      # Browse folder
      "org/gnome/desktop/app-folders/folders/Browse" = {
        name = "Browse";
        apps = [
          "brave-browser.desktop"
          "com.brave.Browser.desktop"
          "chromium-browser.desktop"
        ];
      };

      # Command folder
      "org/gnome/desktop/app-folders/folders/Command" = {
        name = "Command";
        apps = [
          "Helix.desktop"
          "htop.desktop"
          "nvim.desktop"
          "org.gnome.Terminal.desktop"
          "yazi.desktop"
        ];
      };

      # Assist folder
      "org/gnome/desktop/app-folders/folders/Assist" = {
        name = "Assist";
        apps = [
          "org.gnome.Extensions.desktop"
          "org.gnome.Papers.desktop"
          "org.gnome.Settings.desktop"
          "org.gnome.TextEditor.desktop"
        ];
      };

      # Entertain folder
      "org/gnome/desktop/app-folders/folders/Entertain" = {
        name = "Entertain";
        apps = [
          "org.gnome.Loupe.desktop"
          "mpv.desktop"
        ];
      };

      # Keyboard input settings
      "org/gnome/desktop/input-sources" = {
        xkb-options = [
          "compose:ralt"
          "caps:ctrl_modifier"
        ];
      };

      # Remap IBus unicode hotkey to Ctrl+Alt+U (frees Ctrl+Shift+U for Kitty)
      "org/freedesktop/ibus/panel/emoji" = {
        unicode-hotkey = [ "<Control><Alt>u" ];
      };

      # GNOME Terminal - use Stylix theme colors
      "org/gnome/terminal/legacy" = {
        theme-variant = "system";
      };

      # Custom keybindings
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Files";
        command = "nautilus";
        binding = "<Super>f";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "VS Code";
        command = "code";
        binding = "<Super>c";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Kitty";
        command = "kitty";
        binding = "<Super>k";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "Obsidian";
        command = "obsidian";
        binding = "<Super>o";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
        name = "Brave";
        command = "brave";
        binding = "<Super>b";
      };
    };
  };
}
