{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
  };

  xdg.configFile = {
    "kitty/kitty.conf".source = ../files/kitty/kitty.conf;
    "kitty/palenight.conf".source = ../files/kitty/palenight.conf;
  };
}
