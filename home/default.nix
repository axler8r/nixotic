{ config, pkgs, ... }:

{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./btop.nix
    ./claude.nix
    ./dircolors.nix
    ./direnv.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./files.nix
    ./gh.nix
    ./git.nix
    ./gnome.nix
    ./gpg.nix
    ./helix.nix
    ./htop.nix
    ./jq.nix
    ./kitty.nix
    ./neovim.nix
    ./nh.nix
    ./nushell.nix
    ./yazi.nix
    ./ripgrep.nix
    ./starship.nix
    ./stylix.nix
    ./tmux.nix
    ./vscode.nix
    ./zsh.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "axl";
  home.homeDirectory = "/home/axl";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # Version control & development
    gitflow
    parallel
    tig

    # AI coding assistants
    claude-code
    codex

    # Editors & text processing
    universal-ctags

    # Productivity CLI tools
    attr        # Extended file attributes (getfattr/setfattr)
    bfs
    choose
    curl
    dust        # Intuitive disk usage
    duf         # Better df alternative
    fdupes
    gum         # Pretty terminal output (tables, prompts, spinners)
    jq
    lsof
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

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/axl/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
