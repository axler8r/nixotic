{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Plugins (replaces TPM)
    plugins = with pkgs.tmuxPlugins; [
      sensible      # Sane defaults for tmux
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
      # Note: tmux-menus (jaclu/tmux-menus) not in nixpkgs - omitting for now
    ];
  };

  # Use original config file to preserve formatting and avoid Nix escaping
  xdg.configFile."tmux/tmux.conf".source = ../files/tmux/tmux.conf;
}
