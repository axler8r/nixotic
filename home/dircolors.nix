{ config, pkgs, ... }:

{
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  # Use original dir_colors file to preserve formatting
  xdg.configFile."dircolors".source = ../files/dircolors/dir_colors;
}
