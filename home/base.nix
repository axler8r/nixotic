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

  home.homeDirectory = "/home/axl";
  home.packages = with pkgs; [
    (aspellWithDicts (dicts: with dicts; [ en af ]))
    bat
    leaf-markdown-viewer
    # Only the mandoc renderer — man-db provides man/apropos/whatis
    (runCommand "mandoc-bin" {} ''
      mkdir -p $out/bin
      cp ${mandoc}/bin/mandoc $out/bin/
    '')
    tig
  ];
  home.stateVersion = "25.11"; # Please read the comment before changing.
  home.username = "axl";

  programs.home-manager.enable = true;

  xdg.configFile."leaf/config.toml".source = ../files/leaf/config.toml;
}
