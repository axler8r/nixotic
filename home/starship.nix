{ config, pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      palette = "solarized-base64";

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

      # Color palettes
      palettes = {
        material-palenight = {
          primary = "#D0D0D0";
          secondary = "#292D3F";
          background = "#282a36";
          red = "#ff5555";
          orange = "#ffb86c";
          yellow = "#f1fa8c";
          green = "#50fa7b";
          blue = "#8be9fd";
          cyan = "#8be9fd";
          magenta = "#ff79c6";
          violet = "#bd93f9";
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
