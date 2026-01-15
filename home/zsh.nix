{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    history = {
      size = 5000;
      save = 2500;
      path = "${config.home.homeDirectory}/.zsh_history";
      append = true;
      expireDuplicatesFirst = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    autocd = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=cyan";
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" ];
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.zsh-nix-shell;
      }
      {
        name = "zsh-vi-mode";
        file = "zsh-vi-mode.plugin.zsh";
        src = pkgs.zsh-vi-mode;
      }
      {
        name = "zsh-fzf-tab";
        file = "fzf-tab.plugin.zsh";
        src = pkgs.zsh-fzf-tab;
      }
      {
        name = "zsh-completions";
        file = "zsh-completions.plugin.zsh";
        src = pkgs.zsh-completions;
      }
      {
        name = "zsh-forgit";
        file = "forgit.plugin.zsh";
        src = pkgs.zsh-forgit;
      }
    ];

    # Unified init content (replaces initExtraBeforeCompInit and initExtra)
    initContent = lib.mkMerge [
      (lib.mkOrder 550 (builtins.readFile ../files/zsh/completion.zsh))  # Before compinit
      (builtins.readFile ../files/zsh/zshrc)  # Main config
    ];

    sessionVariables = {
      HISTSIZE = "5000";
      SAVEHIST = "2500";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file.".zsh/functions" = {
    source = ../files/zsh/functions;
    recursive = true;
  };

  home.file.".zshalias".source = ../files/zsh/zshalias;

  xdg.dataFile."zsh/site-functions/_uv".text = builtins.readFile (
    pkgs.runCommand "uv-completion" {} ''
      ${pkgs.uv}/bin/uv generate-shell-completion zsh > $out
    ''
  );
}
