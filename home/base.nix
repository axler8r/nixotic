{ pkgs, lib, ... }:

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
    (aspellWithDicts (dicts: with dicts; [ en af ]))
    bat
    # Only the mandoc renderer — man-db provides man/apropos/whatis
    (runCommand "mandoc-bin" {} ''
      mkdir -p $out/bin
      cp ${mandoc}/bin/mandoc $out/bin/
    '')
    tig
  ];

  programs.home-manager.enable = true;
}
