{ pkgs, ... }:
{
  imports = [
    ./base.nix
    ./atuin.nix
    ./bat.nix
    ./claude.nix
    ./codex.nix
    ./eza.nix
    ./fd.nix
    ./gh.nix
    ./gnome.nix
    ./gpg.nix
    ./htop.nix
    ./jq.nix
    ./kitty.nix
    ./neovim.nix
    ./nh.nix
    ./ripgrep.nix
    ./stylix.nix
    ./vscode.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    # AI coding assistants
    claude-code
    codex
    github-copilot-cli

    # Runtime tools for ax (attr, output, docker/git commands)
    attr
    gum
    parallel

    # Productivity CLI tools
    orpie
    tokei
    tree

    # Media
    ffmpeg # also ax media video convert
    mpv

    # Documents
    meowpdf
    typst
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
