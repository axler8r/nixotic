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

      # ── Material Palenight Status Bar (base16) ──
      # base00=#292D3E (bg) base01=#444267 (status bg) base02=#32374D (selection)
      # base03=#676E95 (comments) base04=#8796B0 (dark fg) base05=#959DCB (fg)
      # base0A=#FFCB6B (yellow) base0B=#C3E88D (green) base0D=#82AAFF (blue)
      set -g status on
      set -g status-interval 5
      set -g status-position bottom
      set -g status-justify left
      set -g status-style "bg=#444267,fg=#8796B0"  # base01 bg, base04 fg

      # Left status: session name
      set -g status-left-length 40
      set -g status-left "#[bg=#82AAFF,fg=#292D3E,bold] #S #[bg=#444267,fg=#82AAFF]"  # base0D accent, base00 text

      # Right status: date and hostname
      set -g status-right-length 80
      set -g status-right "#[fg=#676E95]%Y-%m-%d #[fg=#959DCB]%H:%M #[bg=#C3E88D,fg=#292D3E] #h "  # base03, base05, base0B

      # Window status
      set -g window-status-format "#[fg=#676E95] #I:#W "  # base03
      set -g window-status-current-format "#[bg=#32374D,fg=#FFFFFF,bold] #I:#W "  # base02 selection, base07
      set -g window-status-separator ""

      # Pane borders
      set -g pane-border-style "fg=#444267"  # base01
      set -g pane-active-border-style "fg=#82AAFF"  # base0D

      # Message styling
      set -g message-style "bg=#FFCB6B,fg=#292D3E"  # base0A, base00
      set -g message-command-style "bg=#292D3E,fg=#FFCB6B"  # base00, base0A

      # Mode (copy mode) styling
      set -g mode-style "bg=#32374D,fg=#FFFFFF"  # base02 selection, base07
    '';
  };
}
