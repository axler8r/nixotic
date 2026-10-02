{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = builtins.fromTOML (builtins.readFile ../files/starship/starship.toml);
  };
}
