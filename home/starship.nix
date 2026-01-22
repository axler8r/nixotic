{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      palette = "material-palenight";

      # General prompt format
      # Note: In Nix, $variable must be escaped as \$variable in regular strings,
      # or ''$ in multi-line '' strings. We use regular strings with \$ here.
      format = "\$python\$directory\$git_branch\$git_status\$git_metrics\$fill\$status\n";

      # Python virtual environment
      python = {
        format = "([\$symbol\$virtualenv](\$style) )";
        detect_extensions = [ ];
        detect_files = [ ];
        detect_folders = [ ".venv" ];
        pyenv_version_name = true;
        style = "#FFD43B";
        symbol = "󰌠 ";
      };

      # Directory
      directory = {
        format = "[\$symbol\$path](\$style) ";
        read_only = " ";
        read_only_style = "red";
        style = "blue bold";
        truncate_to_repo = false;
        truncation_length = 3;
      };

      # Git branch
      git_branch = {
        format = "[\$symbol\$branch](\$style) ";
        style = "green";
        symbol = " ";
      };

      # Git status (ahead/behind)
      git_status = {
        format = "[\$ahead_behind](\$style) ";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕\${ahead_count}/\${behind_count}";
        style = "dimmed white";
      };

      # Git metrics (added/removed lines)
      git_metrics = {
        format = "[+\$added](\$added_style) [-\$deleted](\$deleted_style)";
        added_style = "bold green";
        deleted_style = "bold red";
        disabled = false;
      };

      # Fill (for spacing/alignment)
      fill = {
        symbol = " ";
      };

      # Pipeline/exit status (right-aligned)
      status = {
        format = "[\$symbol\$pipestatus](\$style) ";
        pipestatus = true;
        pipestatus_separator = "|";
        style = "bold red";
        symbol = "✘ ";
      };

      # Character prompt - static symbols to avoid conflict with zsh-vi-mode
      # Both hook into zle-keymap-select, causing FUNCNEST recursion
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
        vimcmd_symbol = "[➜](bold green)";
        vimcmd_visual_symbol = "[➜](bold green)";
        vimcmd_replace_symbol = "[➜](bold green)";
        vimcmd_replace_one_symbol = "[➜](bold green)";
      };

      # Color palettes
      palettes = {
        # Material Palenight (base16)
        material-palenight = {
          # Shades (base00-base07)
          base00 = "#292D3E";  # Default Background
          base01 = "#444267";  # Lighter Background (status bars)
          base02 = "#32374D";  # Selection Background
          base03 = "#676E95";  # Comments, Invisibles
          base04 = "#8796B0";  # Dark Foreground (status bars)
          base05 = "#959DCB";  # Default Foreground
          base06 = "#959DCB";  # Light Foreground
          base07 = "#FFFFFF";  # Light Background
          # Accents (base08-base0F)
          red = "#F07178";     # base08 - Variables
          orange = "#F78C6C"; # base09 - Constants
          yellow = "#FFCB6B"; # base0A - Classes
          green = "#C3E88D";  # base0B - Strings
          cyan = "#89DDFF";   # base0C - Support/Regex
          blue = "#82AAFF";   # base0D - Functions
          magenta = "#C792EA"; # base0E - Keywords
          violet = "#C792EA";  # alias for magenta
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
