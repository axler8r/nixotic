{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Use original TOML file directly to avoid Nix escaping issues
  xdg.configFile."starship.toml".source = ../files/starship/starship.toml;
}
