{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;

    # Let Stylix handle font and colors, just override specific settings
    settings = {
      # Disable GTK/IBus input method so Ctrl+Shift+U works for unicode input
      "env GLFW_IM_MODULE" = "";
      "env GTK_IM_MODULE" = "";

      # Font behavior (Stylix sets font family and size)
      disable_ligatures = "never";
      adjust_column_width = "-1";  # Tighter character spacing

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
