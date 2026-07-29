{ config, pkgs, lib, ... }:

let
  solarized = {
    lightBackground = "#fdf6e3";
    lightBackgroundContrast = "#eee8d5";
    lightestAccent = "#93a1a1";
    lightAccent = "#839496";
    darkAccent = "#657b83";
    darkestAccent = "#586e75";
    darkBackgroundContrast = "#073642";
    darkBackground = "#002b36";

    red = "#dc322f";
    orange = "#cb4b16";
    yellow = "#b58900";
    green = "#859900";
    cyan = "#2aa198";
    blue = "#268bd2";
    violet = "#6c71c4";
    magenta = "#d33682";
  };
in
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
      highlight = "fg=${solarized.lightestAccent}";
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
      (lib.mkOrder 910 ''
        # Solarized Light shell highlighting
        # Names match docs/colour-token-taxonomy.md (Appendix E) for readability.
        typeset -gA ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[default]='fg=${solarized.lightAccent}'
        ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=${solarized.red},bold'
        ZSH_HIGHLIGHT_STYLES[commandunknown]='fg=${solarized.red},bold'
        ZSH_HIGHLIGHT_STYLES[comment]='fg=${solarized.lightAccent},italic'
        ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[alias]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[global-alias]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[precommand]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[command]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[function]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[builtin]='fg=${solarized.green},bold'
        ZSH_HIGHLIGHT_STYLES[path]='fg=${solarized.blue}'
        ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=${solarized.lightAccent}'
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=${solarized.blue}'
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=${solarized.blue}'
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=${solarized.cyan}'
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=${solarized.cyan}'
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=${solarized.cyan}'
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[assign]='fg=${solarized.blue}'
        ZSH_HIGHLIGHT_STYLES[globbing]='fg=${solarized.blue}'
        ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=${solarized.lightAccent}'
        ZSH_HIGHLIGHT_STYLES[redirection]='fg=${solarized.lightAccent}'
        ZSH_HIGHLIGHT_STYLES[named-fd]='fg=${solarized.lightAccent}'
        ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]='fg=${solarized.violet}'
        ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=${solarized.cyan}'
      '')
      # After plugins (900) and fzf (910): load fzf keybindings.
      # Tab binding is deferred into zvm_after_init so zsh-vi-mode cannot
      # clobber it when it fires its own init hook after shell startup.
      (lib.mkOrder 920 ''
        source <(${pkgs.fzf}/bin/fzf --zsh)
        zvm_after_init() {
          bindkey -M viins '^I' fzf-tab-complete
          bindkey -M emacs '^I' fzf-tab-complete
        }
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
    historyWidget.nushell.command = "";  # Atuin owns Ctrl-R in nushell
    defaultOptions = [
      # Solarized Light — docs/colour-token-taxonomy.md (Appendix H)
      "--color=bg+:#eee8d5"
      "--color=bg:#fdf6e3"
      "--color=border:#268bd2"
      "--color=fg:#839496"
      "--color=fg+:#657b83"
      "--color=gutter:#fdf6e3"
      "--color=header:#d33682"
      "--color=hl:#b58900"
      "--color=hl+:#b58900"
      "--color=info:#839496"
      "--color=marker:#859900"
      "--color=pointer:#268bd2"
      "--color=prompt:#268bd2"
      "--color=query:#657b83"
      "--color=scrollbar:#93a1a1"
      "--color=separator:#93a1a1"
      "--color=spinner:#2aa198"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file.".zsh/functions" = {
    source = ../files/zsh/functions;
    recursive = true;
  };

  home.file.".zsh/lib" = {
    source = ../files/zsh/lib;
    recursive = true;
  };

  home.file.".zshalias".source = ../files/zsh/zshalias;

  xdg.dataFile."zsh/site-functions/_uv".text = builtins.readFile (
    pkgs.runCommand "uv-completion" {} ''
      ${pkgs.uv}/bin/uv generate-shell-completion zsh > $out
    ''
  );

  home.packages = [
    (pkgs.runCommand "zsh-completions-nixotic" { } ''
      mkdir -p $out/share/zsh/site-functions
      cp ${../files/zsh/completions}/_* $out/share/zsh/site-functions/
    '')
  ];
}
