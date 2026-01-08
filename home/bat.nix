{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;
  };

  # Use original config file to preserve formatting and avoid escaping issues
  xdg.configFile."bat/config".source = ../files/bat/config;
}
