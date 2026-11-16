{ config, pkgs, ... }:

{
  stylix = {
    enable = true;
    polarity = "light";
    # A source path, not a derivation: Stylix parses it without import-from-derivation.
    base16Scheme = ./files/stylix/solarized-light-nixotic.yaml;

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
        applications = 10;
        desktop = 10;
        terminal = 9;
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

    # Stylix kmscon module uses removed nixpkgs options (extraConfig, fonts)
    targets.kmscon.enable = false;
  };
}
