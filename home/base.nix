{ pkgs, ... }:

{
  imports = [
    ./dircolors.nix
    ./direnv.nix
    ./files.nix
    ./git.nix
    ./helix.nix
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home.username = "axl";
  home.homeDirectory = "/home/axl";
  home.stateVersion = "25.11"; # Please read the comment before changing.

  home.packages = with pkgs; [
    bat
    tig
  ];

  programs.home-manager.enable = true;
}
