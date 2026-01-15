{ config, pkgs, ... }:

{
  programs.ranger = {
    enable = true;
  };

  xdg.configFile."ranger/rc.conf".source = ../files/ranger/rc.conf;
  xdg.configFile."ranger/scope.sh" = {
    source = ../files/ranger/scope.sh;
    executable = true;
  };
}
