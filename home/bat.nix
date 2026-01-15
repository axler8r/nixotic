{ config, pkgs, ... }:

{
  programs.bat = {
    enable = true;
  };

  xdg.configFile."bat/config".source = ../files/bat/config;
}
