{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
  };

  # Use original config files to preserve formatting and comments
  xdg.configFile = {
    "kitty/kitty.conf".source = ../files/kitty.conf;
    "kitty/Solarized_Dark.conf".source = ../files/Solarized_Dark.conf;
    "kitty/Solarized_Light.conf".source = ../files/Solarized_Light.conf;
  };
}
