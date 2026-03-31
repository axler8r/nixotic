{ config, pkgs, ... }:

{
  xdg.configFile."helix/themes/nixotic_solarized_light.toml".text = ''
    inherits = "solarized_light"

    "comment" = { fg = "base0", modifiers = ["italic"] }
    "comment.block.documentation" = { fg = "base0", modifiers = ["italic"] }
    "operator" = "base0"
    "punctuation" = "base0"
    "punctuation.delimiter" = "base0"
    "punctuation.bracket" = "base0"

    "keyword" = { fg = "green", modifiers = ["bold"] }
    "keyword.control" = { fg = "green", modifiers = ["bold"] }
    "keyword.storage" = { fg = "green", modifiers = ["bold"] }

    "variable" = "blue"
    "variable.parameter" = "blue"
    "variable.other.member" = "blue"
    "variable.builtin" = "blue"

    "constant" = "blue"
    "constant.numeric" = "cyan"
    "constant.builtin.boolean" = "cyan"

    "string" = "cyan"
    "string.special" = "violet"
    "string.regexp" = "violet"

    "type" = "yellow"
    "type.builtin" = "yellow"
    "constructor" = "yellow"

    "function" = { fg = "orange", modifiers = ["italic"] }
    "function.method" = { fg = "orange", modifiers = ["italic"] }
    "function.builtin" = { fg = "orange", modifiers = ["italic"] }

    "keyword.control.import" = "magenta"
    "keyword.directive" = "magenta"
    "namespace" = "magenta"
    "attribute" = "magenta"

    "diagnostic.error" = "red"
    "diagnostic.warning" = "orange"
    "diagnostic.info" = "cyan"

    [palette]
    base0 = "#839496"
    green = "#859900"
    blue = "#268bd2"
    cyan = "#2aa198"
    yellow = "#b58900"
    orange = "#cb4b16"
    violet = "#6c71c4"
    magenta = "#d33682"
    red = "#dc322f"
  '';

  programs.helix = {
    enable = true;

    settings = {
      theme = "nixotic_solarized_light";

      editor = {
        line-number = "relative";
        cursorline = true;
        auto-save = true;
        rulers = [70 80 110];
        scrolloff = 13;
        color-modes = true;
        bufferline = "multiple";  # Show tabs when multiple buffers open
        auto-pairs = true;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        # Git diff in gutter (like gitsigns)
        gutters = ["diagnostics" "spacer" "line-numbers" "spacer" "diff"];

        # Whitespace rendering (helps spot trailing spaces)
        whitespace = {
          render = {
            space = "none";
            tab = "all";
            newline = "none";
          };
          characters = {
            tab = "→";
          };
        };

        # Statusline (like lualine)
        statusline = {
          left = ["mode" "spinner" "file-name" "file-modification-indicator"];
          center = ["diagnostics"];
          right = ["selections" "position" "file-encoding" "file-type"];
          separator = "│";
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };

        file-picker.hidden = false;

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };

      keys.normal = {
        space.w = ":write";
        space.q = ":quit";
        space.f = "file_picker";
        space.b = "buffer_picker";
        space.s = "symbol_picker";
        space.S = "workspace_symbol_picker";
        space.g = "changed_file_picker";
        space.d = "diagnostics_picker";
        space.r = ":reload";
        space.space = "last_picker";

        # Buffer navigation (like :bnext/:bprev)
        "A-." = ":buffer-next";
        "A-," = ":buffer-previous";

        # Git-related (] then g, [ then g)
        "]" = { "g" = "goto_next_change"; };
        "[" = { "g" = "goto_prev_change"; };

        # Toggle spell check (like <leader>sp in neovim)
        space.t.s = ":toggle-option soft-wrap.enable";

        # Window management
        "C-h" = "jump_view_left";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
        "C-l" = "jump_view_right";
      };

      keys.insert = {
        # Quick escape
        "j" = { "k" = "normal_mode"; };
      };
    };

    languages = {
      language = [
        { name = "c-sharp"; auto-format = true; }
        { name = "elixir"; auto-format = true; }
        { name = "java"; auto-format = true; }
        { name = "julia"; auto-format = true; }
        { name = "markdown"; auto-format = true; soft-wrap.enable = true; }
        { name = "nix"; auto-format = true; }
        { name = "python"; auto-format = true; }
        { name = "rust"; auto-format = true; }
        { name = "toml"; auto-format = true; }
      ];
    };

    # LSP servers for Helix
    extraPackages = with pkgs; [
      pyright              # Python
      rust-analyzer        # Rust
      elixir-ls            # Elixir
      csharp-ls            # C# / .NET
      jdt-language-server  # Java
      nil                  # Nix
    ];
  };
}
