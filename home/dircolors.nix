{ config, pkgs, ... }:

{
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."dircolors".source = ../files/dircolors/dir_colors;
}
