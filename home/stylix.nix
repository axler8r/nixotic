{ config, pkgs, ... }:

{
  # Disable Stylix for apps where we prefer manual config
  stylix.targets = {
    # Use custom palenight theme from files/kitty/
    kitty.enable = false;

    # Keep custom starship Solarized palette
    starship.enable = false;

    # Disable Qt theming - let GNOME handle it via qgnomeplatform
    qt.enable = false;
  };

  # GTK icon theme - Papirus for Solarized Light
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };
}
