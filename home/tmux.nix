{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Core settings via Home Manager options
    prefix = "C-a";
    escapeTime = 1;
    historyLimit = 4096;
    baseIndex = 1;
    keyMode = "vi";
    terminal = "xterm-256color";
    mouse = false;

    plugins = with pkgs.tmuxPlugins; [
      yank          # System clipboard integration
      tmux-fzf      # FZF integration for sessions/windows/panes
      {
        plugin = resurrect;
        extraConfig = "";
      }
      {
        plugin = continuum;
        extraConfig = "set -g @continuum-restore 'on'";
      }
      logging
    ];

    extraConfig = builtins.readFile ../files/tmux/tmux.conf;
  };
}
