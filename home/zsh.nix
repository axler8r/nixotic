{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    # History settings
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

    # Options from .zshrc
    autocd = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=cyan";
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" ];
    };

    # Completion settings
    completionInit = ''
      autoload -Uz compinit
      compinit
      zstyle ':completion:*' completer _complete _ignored
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' '+r:|[._-]=* r:|=*'
    '';

    # initExtra for zsh init
    initExtra = ''
      # Features
      autoload -Uz zmv
      autoload -Uz edit-command-line
      zle -N edit-command-line

      # Key bindings
      bindkey -v
      bindkey -M vicmd E edit-command-line

      # Additional options not covered by Home Manager
      setopt auto_list
      setopt auto_menu
      setopt bang_hist
      setopt complete_in_word
      setopt correct
      setopt pushd_ignore_dups
      setopt pushd_silent
      setopt pushd_to_home
      setopt short_loops
      unsetopt beep

      # Environment
      export GPG_TTY=$(tty)
      if [[ -x $(which nvim 2> /dev/null) ]]; then
          EDITOR=$(which nvim)
          VISUAL=''${EDITOR}
      elif [[ -x $(which vim 2> /dev/null) ]]; then
          EDITOR=$(which vim)
          VISUAL=''${EDITOR}
      fi
      [[ -x $(which erl 2> /dev/null) ]] && export ERL_AFLAGS="-kernel shell_history enabled"

      # History hook - ignore specific commands
      zshaddhistory() {
          emulate -L zsh
          setopt extendedglob
          if [[ $1 == (#b)(alias|bat|btop|cat|cd|fd|find|git|exit|head|history|htop|ipython|jupyter|locate|man|nvtop|pass|pwd|tail|tig|top|which|who)* ]]; then
              return 1
          fi
          return 0
      }

      # Python site packages
      if [[ -x $(which python3 2> /dev/null) ]]; then
          SITE_PACKAGE_HOME=$(python3 -m site --user-site)
          export SITE_PACKAGE_HOME
      fi

      # PATH additions
      typeset -aU path
      path=(''${HOME}/.local/bin $path)
      path+=(''${HOME}/.zsh/functions)

      # FPATH for functions
      typeset -aU fpath
      fpath=(''${HOME}/.zsh/functions $fpath)
      fpath=(''${HOME}/.zsh/completions $fpath)

      # Autoload user functions
      if [[ -d ''${HOME}/.zsh/functions ]]; then
        for func in ''${HOME}/.zsh/functions/*; do
          autoload -Uz ''${func:t}
        done
      fi

      # Application integrations
      [[ -x $(which uv 2> /dev/null) ]] && eval "$(uv generate-shell-completion zsh)"
      [[ -x $(which uvx 2> /dev/null) ]] && eval "$(uvx --generate-shell-completion zsh)"

      # Source aliases (complex aliases with local variables and functions)
      [[ -f ''${HOME}/.zshalias ]] && source ''${HOME}/.zshalias

      # Starship prompt (replaces Powerline)
      eval "$(starship init zsh)"
    '';

    # Environment variables
    sessionVariables = {
      HISTSIZE = "5000";
      SAVEHIST = "2500";
    };
  };

  # fzf integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # zoxide integration (z command)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Copy functions directory
  home.file.".zsh/functions" = {
    source = ../files/zsh/functions;
    recursive = true;
  };

  # Copy aliases file (complex, kept as source file)
  home.file.".zshalias".source = ../files/zsh/zshalias;
}
