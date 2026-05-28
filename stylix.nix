{ config, pkgs, ... }:

let
  solarizedLightScheme = pkgs.writeText "solarized-light-nixotic.yaml" ''
    scheme: "Solarized Light (Nixotic)"
    author: "axl"
    base00: "fdf6e3"
    base01: "eee8d5"
    base02: "93a1a1"
    base03: "839496"
    base04: "657b83"
    base05: "839496"
    base06: "073642"
    base07: "002b36"
    base08: "268bd2"
    base09: "2aa198"
    base0A: "b58900"
    base0B: "2aa198"
    base0C: "6c71c4"
    base0D: "cb4b16"
    base0E: "859900"
    base0F: "d33682"
  '';
in

{
  stylix = {
    enable = true;
    polarity = "light";
    base16Scheme = "${solarizedLightScheme}";

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
  };
}
