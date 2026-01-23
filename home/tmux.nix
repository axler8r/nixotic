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
    ];

    extraConfig = ''
      # ── Additional Server Settings ──
      set -sg display-time 4096
      set -sg renumber-windows on
      set -sg allow-rename off

      # Terminal overrides for true color
      set -sa terminal-overrides ",xterm*:Tc"

      # Window settings
      set -wg automatic-rename off
      set -wg pane-base-index 1

      # ── Key Bindings ──
      unbind C-?
      bind ? list-keys
      unbind C-c
      bind c new-window
      unbind C-r
      unbind [
      bind Escape copy-mode
      unbind %
      unbind |
      bind | split-window -h
      unbind '"'
      unbind -
      bind - split-window -v -d
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind H resize-pane -L 5
      bind J resize-pane -D 3
      bind K resize-pane -U 3
      bind L resize-pane -R 5
      unbind E
      bind E set-window-option synchronize-panes on
      unbind e
      bind e set-window-option synchronize-panes off
      unbind p
      bind p paste-buffer
      bind a send-prefix
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Reloaded!"

      # ── Solarized Light Status Bar (base16) ──
      # base00=#fdf6e3 (bg) base01=#eee8d5 (status bg) base02=#eee8d5 (selection)
      # base03=#93a1a1 (comments) base04=#839496 (dark fg) base05=#657b83 (fg)
      # base0A=#b58900 (yellow) base0B=#859900 (green) base0D=#268bd2 (blue)
      set -g status on
      set -g status-interval 5
      set -g status-position bottom
      set -g status-justify left
      set -g status-style "bg=#eee8d5,fg=#657b83"  # base01 bg, base05 fg

      # Left status: session name
      set -g status-left-length 40
      set -g status-left "#[bg=#268bd2,fg=#fdf6e3,bold] #S #[bg=#eee8d5,fg=#268bd2]"  # base0D accent, base00 text

      # Right status: date and hostname
      set -g status-right-length 80
      set -g status-right "#[fg=#93a1a1]%Y-%m-%d #[fg=#657b83]%H:%M #[bg=#859900,fg=#fdf6e3] #h "  # base03, base05, base0B

      # Window status
      set -g window-status-format "#[fg=#93a1a1] #I:#W "  # base03
      set -g window-status-current-format "#[bg=#fdf6e3,fg=#002b36,bold] #I:#W "  # base00 selection, base07
      set -g window-status-separator ""

      # Pane borders
      set -g pane-border-style "fg=#eee8d5"  # base01
      set -g pane-active-border-style "fg=#268bd2"  # base0D

      # Message styling
      set -g message-style "bg=#b58900,fg=#fdf6e3"  # base0A, base00
      set -g message-command-style "bg=#fdf6e3,fg=#b58900"  # base00, base0A

      # Mode (copy mode) styling
      set -g mode-style "bg=#eee8d5,fg=#002b36"  # base02 selection, base07
    '';
  };
}
