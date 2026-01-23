{ config, pkgs, ... }:

{
  programs.ranger = {
    enable = true;

    settings = {
      # Color scheme (snow is a light theme that works well with Solarized Light terminals)
      colorscheme = "snow";

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

  # Scope script for syntax-highlighted previews
  xdg.configFile."ranger/scope.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Ranger scope.sh for syntax highlighting

      set -o noclobber -o noglob -o nounset -o pipefail
      IFS=$'\n'

      FILE_PATH="''${1}"
      FILE_EXTENSION="''${FILE_PATH##*.}"
      FILE_EXTENSION_LOWER="$(printf "%s" "''${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

      # Syntax highlight with pygments using native style (dark theme compatible)
      highlight_file() {
          pygmentize -f terminal256 -O style=native -g "''${FILE_PATH}" 2>/dev/null && exit 0
      }

      # Try syntax highlighting
      highlight_file

      # Fallback to plain text
      cat "''${FILE_PATH}"
      exit 0
    '';
  };
}
