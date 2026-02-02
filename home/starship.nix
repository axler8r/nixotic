{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      palette = "solarized-light";

      # General prompt format
      # Note: In Nix, $variable must be escaped as \$variable in regular strings,
      # or ''$ in multi-line '' strings. We use regular strings with \$ here.
      format = "󰅂 \$nix_shell\$directory\$git_branch\$git_status\$git_metrics \$status\n󰅁 ";

      # Nix shell (direnv + flake devShells)
      nix_shell = {
        format = "([\\[\$symbol\$name\\]](\$style) )";
        symbol = "";
        style = "cyan";
        impure_msg = "(impure)";
        pure_msg = "pure";
      };

      # Directory
      directory = {
        format = "[\$path](\$style) ";
        read_only = " ";
        read_only_style = "red";
        style = "blue bold";
        truncate_to_repo = false;
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      # Git branch
      git_branch = {
        format = "[\$symbol\$branch](\$style) ";
        style = "green";
        symbol = " ";
      };

      # Git status (ahead/behind)
      git_status = {
        format = "[\$ahead_behind](\$style) ";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕\${ahead_count}/\${behind_count}";
        style = "base1";
      };

      # Git metrics (added/removed lines)
      git_metrics = {
        format = "([+\$added](\$added_style) )([-\$deleted](\$deleted_style))";
        added_style = "bold green";
        deleted_style = "bold red";
        disabled = false;
      };

      # Fill (for spacing/alignment)
      fill = {
        symbol = " ";
      };

      # Pipeline/exit status
      status = {
        disabled = false;
        format = "([\\[‼ \$status\\]](\$style))";
        pipestatus = true;
        pipestatus_format = "([\\[‼ \$pipestatus\\]](\$style))";
        pipestatus_separator = " 󰅂 ";
        pipestatus_segment_format = "\$status";
        style = "bold red";
        symbol = "‼";
      };

      # Character prompt - static symbols to avoid conflict with zsh-vi-mode
      # Both hook into zle-keymap-select, causing FUNCNEST recursion
      # character = {
      #   success_symbol = "[ ](bold green)";
      #   error_symbol = "[ ](bold red)";
      #   vimcmd_symbol = "[➜](bold green)";
      #   vimcmd_visual_symbol = "[➜](bold green)";
      #   vimcmd_replace_symbol = "[➜](bold green)";
      #   vimcmd_replace_one_symbol = "[➜](bold green)";
      # };

      # Color palettes
      palettes = {
        # Solarized Light (base16)
        solarized-light = {
          # Shades (base00-base07)
          base00 = "#fdf6e3";  # Default Background (lightest)
          base01 = "#eee8d5";  # Lighter Background (status bars)
          base02 = "#eee8d5";  # Selection Background
          base03 = "#93a1a1";  # Comments, Invisibles
          base04 = "#839496";  # Dark Foreground (status bars)
          base05 = "#657b83";  # Default Foreground
          base06 = "#586e75";  # Light Foreground
          base07 = "#002b36";  # Darkest (for contrast)
          # Accents (base08-base0F)
          red = "#dc322f";     # base08 - Variables
          orange = "#cb4b16"; # base09 - Constants
          yellow = "#b58900"; # base0A - Classes
          green = "#859900";  # base0B - Strings
          cyan = "#2aa198";   # base0C - Support/Regex
          blue = "#268bd2";   # base0D - Functions
          magenta = "#d33682"; # base0E - Keywords
          violet = "#6c71c4";  # alias for violet
        };

        solarized-base64 = {
          primary = "#fdf6e3";
          secondary = "#073642";
          background = "#002b36";
          base03 = "#002b36";
          base02 = "#073642";
          base01 = "#586e75";
          base00 = "#657b83";
          base0 = "#657b83";
          base1 = "#657b83";
          base2 = "#eee8d5";
          base3 = "#fdf6e3";
          red = "#dc322f";
          orange = "#cb4b16";
          yellow = "#b58900";
          green = "#859900";
          blue = "#268bd2";
          cyan = "#2aa198";
          magenta = "#d33682";
          violet = "#6c71c4";
        };
      };
    };
  };
}
