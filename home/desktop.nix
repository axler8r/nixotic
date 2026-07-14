{ pkgs, ... }:

{
  imports = [
    ./base.nix
    ./atuin.nix
    ./bat.nix
    ./btop.nix
    ./claude.nix
    ./codex.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./gh.nix
    ./gnome.nix
    ./gpg.nix
    ./htop.nix
    ./jq.nix
    ./kitty.nix
    ./neovim.nix
    ./nh.nix
    ./nushell.nix
    ./ripgrep.nix
    ./stylix.nix
    ./vscode.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    # Version control & development
    gitflow
    parallel

    # AI coding assistants
    claude-code
    codex

    # Editors & text processing
    universal-ctags

    # Productivity CLI tools
    attr
    bfs
    choose
    curl
    dust
    duf
    fdupes
    gum
    jq
    lsof
    orpie
    p7zip
    pv
    sd
    socat
    strace
    tokei
    tree
    wget
    yq

    # Nushell plugins
    nushellPlugins.gstat
    nushellPlugins.highlight
    nushellPlugins.polars
    nushellPlugins.query

    # Media
    ffmpeg
    mpv
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
