{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;

    settings = {
      # Solarized Light colors
      background            = "#fdf6e3";
      foreground            = "#839496";
      selection_foreground  = "#d33682";
      selection_background  = "#eee8d5";

      # ANSI color palette
      color0  = "#073642";
      color1  = "#dc322f";
      color2  = "#859900";
      color3  = "#b58900";
      color4  = "#268bd2";
      color5  = "#d33682";
      color6  = "#2aa198";
      color7  = "#eee8d5";
      color8  = "#002b36";
      color9  = "#cb4b16";
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
      adjust_column_width = "-1";  # Tighter character spacing
      font_size = 10.0;
      disable_ligatures = "never";

      # Cursor
      cursor = "#d33682";
      cursor_text_color = "#eee8d5";
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

      # Tab bar
      tab_bar_style = "powerline";
    };

    keybindings = {
      "kitty_mod+u" = "kitten unicode_input";
      "ctrl+shift+u" = "kitten unicode_input";
    };
  };
}
