{ config, pkgs, ... }:

{
  # Disable Stylix for apps where we prefer manual config
  stylix.targets = {
    # Keep custom starship Solarized Light palette
    starship.enable = false;

    # Disable Qt theming - let GNOME handle it via qgnomeplatform
    qt.enable = false;

    # Let VS Code manage its own settings for cross-platform Settings Sync
    vscode.enable = false;
  };

  # GTK icon theme - Papirus-Light for Solarized Light theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Light";
      package = pkgs.papirus-icon-theme;
    };
  };
}
