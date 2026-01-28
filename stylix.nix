{ config, pkgs, ... }:

{
  stylix = {
    enable = true;
    polarity = "light";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-light.yaml";

    # Wallpaper
    image = ./files/wallpapers/Wallpaper00.jpg;

    # Fonts - use Cascadia Code as monospace (includes Nerd Font glyphs since v2404)
    fonts = {
      monospace = {
        package = pkgs.cascadia-code;
        name = "Cascadia Code";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 11;
        desktop = 10;
        terminal = 11;
      };
    };

    # Cursor theme
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Disable Chromium/Brave theming (allows manual theme installation)
    targets.chromium.enable = false;
  };
}
