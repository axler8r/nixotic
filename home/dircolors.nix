{ config, pkgs, ... }:

{
  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;

    extraConfig = builtins.readFile ../files/dircolors/dir_colors;
  };
}
