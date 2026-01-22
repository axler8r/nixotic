{ config, pkgs, ... }:

{
  # Disable Stylix for apps where we prefer manual config
  stylix.targets = {
    # Use custom palenight theme from files/kitty/
    kitty.enable = false;

    # Keep custom starship Material Palenight palette
    starship.enable = false;

    # Disable Qt theming - let GNOME handle it via qgnomeplatform
    qt.enable = false;

    # Let VS Code manage its own settings for cross-platform Settings Sync
    vscode.enable = false;
  };

  # GTK icon theme - Papirus-Dark for Palenight theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };
}
