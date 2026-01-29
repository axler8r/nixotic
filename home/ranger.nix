{ config, pkgs, ... }:

{
  programs.ranger = {
    enable = true;

    settings = {
      # Stylix manages colorscheme

      # Syntax highlighting for file previews
      preview_script = "~/.config/ranger/scope.sh";
      use_preview_script = true;

      # Draw borders between panes
      draw_borders = "both";

      # Image previews using kitty protocol
      preview_images = true;
      preview_images_method = "kitty";

      # Relative line numbers like vim
      line_numbers = "relative";
      dirname_in_tabs = true;

      # Pane sizes
      column_ratios = "1,3,4";

      # Show hidden files
      show_hidden = true;

      # Confirm before deleting
      confirm_on_delete = "always";
    };
  };

  # Scope script for syntax-highlighted previews using bat
  xdg.configFile."ranger/scope.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Ranger scope.sh for syntax highlighting via bat

      set -o noclobber -o noglob -o nounset -o pipefail
      IFS=$'\n'

      FILE_PATH="''${1}"

      # Use bat with base16 theme (no background colors, works on any terminal background)
      bat --color=always --style=plain --paging=never --theme="base16" "''${FILE_PATH}" 2>/dev/null && exit 0

      # Fallback to plain text
      cat "''${FILE_PATH}"
      exit 0
    '';
  };
}
