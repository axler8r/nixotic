{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    completionInit = ''
      autoload -Uz compinit
      compinit
      zstyle ':completion:*' completer _complete _ignored
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' '+r:|[._-]=* r:|=*'
    '';

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
        file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
        src = pkgs.zsh-nix-shell;
      }
      {
        name = "zsh-vi-mode";
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        src = pkgs.zsh-vi-mode;
      }
      {
        name = "zsh-fzf-tab";
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
        src = pkgs.zsh-fzf-tab;
      }
      # zsh-completions adds to fpath, no plugin file needed
      {
        name = "zsh-forgit";
        file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
        src = pkgs.zsh-forgit;
      }
    ];

    # Main config loaded via initContent
    initContent = lib.mkMerge [
      (builtins.readFile ../files/zsh/zshrc)
      # After plugins (900) and fzf (910): load fzf keybindings then rebind Tab to fzf-tab
      (lib.mkOrder 920 ''
        source <(${pkgs.fzf}/bin/fzf --zsh)
        bindkey -M viins '^I' fzf-tab-complete
        bindkey -M emacs '^I' fzf-tab-complete
      '')
    ];

    sessionVariables = {
      HISTSIZE = "5000";
      SAVEHIST = "2500";
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = false;  # Disabled: conflicts with fzf-tab
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
