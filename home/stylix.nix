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

    # Terminal and code-adjacent apps: manual themes keep shell and editor
    # colors independent from each other and from the base16 palette
    kitty.enable = false;
    helix.enable = false;
    bat.enable = false;
    yazi.enable = false;
    btop.enable = false;
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
