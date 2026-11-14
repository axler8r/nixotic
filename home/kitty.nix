{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.kitty = {
    enable = true;

    settings = {
      # Solarized Light colors
      background = "#fdf6e3";
      foreground = "#839496";
      selection_foreground = "#d33682";
      selection_background = "#eee8d5";

      # ANSI color palette
      color0 = "#073642";
      color1 = "#dc322f";
      color2 = "#859900";
      color3 = "#b58900";
      color4 = "#268bd2";
      color5 = "#d33682";
      color6 = "#2aa198";
      color7 = "#eee8d5";
      color8 = "#002b36";
      color9 = "#cb4b16";
      color10 = "#93a1a1";
      color11 = "#839496";
      color12 = "#657b83";
      color13 = "#6c71c4";
      color14 = "#586e75";
      color15 = "#fdf6e3";

      # Disable GTK/IBus input method so Ctrl+Shift+U works for unicode input
      "env GLFW_IM_MODULE" = "";
      "env GTK_IM_MODULE" = "";

      # Font behavior
      # adjust_column_width = "-1";  # Tighter character spacing
      font_size = 9.0;
      disable_ligatures = "never";

      # Cursor
      cursor = "#d33682";
      cursor_text_color = "#fdf6e3";
      cursor_blink_interval = "-2";
      cursor_stop_blinking_after = 20;

      # URLs
      url_color = "#268bd2";
      url_style = "straight";

      # Selection
      copy_on_select = "yes";
      strip_trailing_spaces = "smart";

      # Window
      remember_window_size = "yes";
      initial_window_width = "258c";
      initial_window_height = "98c";
      hide_window_decorations = "yes";
      background_opacity = lib.mkForce "0.98";
      wayland_titlebar_color = "background";

      # Remote control (used by Start-TypstPreview to build pane layouts)
      allow_remote_control = "yes";

      # Tab bar
      tab_bar_style = "powerline";

      # Panes: tmux-style splits; stack is the zoom target
      enabled_layouts = "splits,stack";
      active_border_color = "#268bd2"; # ui.border_active
      inactive_border_color = "#eee8d5"; # ui.border
    };

    # tmux-like bindings on kitty_mod (ctrl+shift), mirroring files/tmux/tmux.conf.
    # kitty "window" = tmux pane; kitty "tab" = tmux window.
    keybindings = {
      "kitty_mod+u" = "kitten unicode_input";
      "ctrl+shift+u" = "kitten unicode_input";

      # Move between panes (replaces previous/next tab and scroll line)
      "kitty_mod+left" = "neighboring_window left";
      "kitty_mod+right" = "neighboring_window right";
      "kitty_mod+up" = "neighboring_window up";
      "kitty_mod+down" = "neighboring_window down";

      # Split: | side by side, - stacked keeping focus (tmux split-window -v -d)
      "kitty_mod+backslash" = "launch --location=vsplit --cwd=current";
      "kitty_mod+minus" = "launch --location=hsplit --cwd=current --keep-focus";

      # Zoom the active pane (tmux resize-pane -Z)
      "kitty_mod+z" = "toggle_layout stack";

      # List and search key bindings (tmux list-keys); replaces search_scrollback,
      # which stays reachable via kitty_mod+h then /
      "kitty_mod+slash" = "command_palette";
    }
    # Go to tab N (tmux select-window -t N)
    // lib.listToAttrs (
      map (n: lib.nameValuePair "kitty_mod+${toString n}" "goto_tab ${toString n}") (lib.range 1 9)
    );

    # Resize mode (tmux H/J/K/L): kitty_mod+r, then arrows or hjkl repeatedly;
    # = resets, esc/enter or any other key leaves.
    extraConfig = ''
      map --new-mode resize --on-unknown end kitty_mod+r
      map --mode resize left  resize_window narrower 5
      map --mode resize h     resize_window narrower 5
      map --mode resize right resize_window wider 5
      map --mode resize l     resize_window wider 5
      map --mode resize up    resize_window taller 3
      map --mode resize k     resize_window taller 3
      map --mode resize down  resize_window shorter 3
      map --mode resize j     resize_window shorter 3
      map --mode resize equal resize_window reset
      map --mode resize esc   pop_keyboard_mode
      map --mode resize enter pop_keyboard_mode
    '';
  };
}
