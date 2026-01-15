{ config, pkgs, ... }:

{
  programs.nh = {
    enable = true;
    flake = "/home/axl/.nixotic";
  };
}
