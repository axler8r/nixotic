{ config, pkgs, ... }:

{
  xdg.configFile."helix/themes/nixotic_solarized_light.toml".text = ''
    # Nixotic Solarized Light — docs/colour-token-taxonomy.md (Appendix B)
    inherits = "solarized_light"

    # ── Code — Core ──
    "comment"                       = { fg = "base0", modifiers = ["italic"] }
    "comment.block.documentation"   = { fg = "base0", modifiers = ["italic"] }
    "operator"                      = "base0"
    "punctuation"                   = "base0"
    "punctuation.delimiter"         = "base0"
    "punctuation.bracket"           = "base0"

    "keyword"                       = { fg = "green", modifiers = ["bold"] }
    "keyword.control"               = { fg = "green", modifiers = ["bold"] }
    "keyword.storage"               = { fg = "green", modifiers = ["bold"] }

    "variable"                      = "blue"
    "variable.parameter"            = "blue"
    "variable.other.member"         = "blue"
    "variable.builtin"              = "blue"
    "constant"                      = "blue"
    "constant.numeric"              = "cyan"
    "constant.builtin.boolean"      = "cyan"

    "string"                        = "cyan"
    "string.special"                = "violet"
    "string.regexp"                 = "violet"

    "type"                          = "yellow"
    "type.builtin"                  = "yellow"
    "constructor"                   = "yellow"

    "function"                      = { fg = "orange", modifiers = ["italic"] }
    "function.method"               = { fg = "orange", modifiers = ["italic"] }
    "function.builtin"              = { fg = "orange", modifiers = ["italic"] }

    "keyword.control.import"        = "magenta"
    "keyword.directive"             = "magenta"
    "namespace"                     = "magenta"
    "attribute"                     = "magenta"

    # ── Markup ──
    "tag"                           = { fg = "green", modifiers = ["bold"] }

    # ── Diff / VCS ──
    "diff.plus"                     = "green"
    "diff.minus"                    = "red"
    "diff.delta"                    = "yellow"

    # ── Diagnostics ──
    "diagnostic.error"              = "red"
    "diagnostic.warning"            = "orange"
    "diagnostic.info"               = "cyan"
    "diagnostic.hint"               = "cyan"

    # ── UI Chrome ──
    "ui.text"                       = "base0"
    "ui.background"                 = { bg = "light_bg" }
    "ui.linenr"                     = "base0"
    "ui.linenr.selected"            = { fg = "base00", modifiers = ["bold"] }
    "ui.cursor"                     = { fg = "base3", bg = "magenta", modifiers = ["bold"] }
    "ui.cursor.normal"              = { fg = "base3", bg = "magenta", modifiers = ["bold"] }
    "ui.cursor.match"               = { fg = "yellow", modifiers = ["bold"] }
    "ui.cursorline.primary"         = { bg = "base2" }
    "ui.selection"                  = { fg = "base3", bg = "base00" }
    "ui.highlight"                  = { fg = "base1" }
    "ui.highlight.frameline"        = { fg = "yellow", modifiers = ["bold"] }
    "ui.virtual.inlay-hint"         = { fg = "base1", modifiers = ["italic"] }
    "ui.virtual.indent-guide"       = { fg = "base2" }
    "ui.gutter"                     = { bg = "base2" }
    "ui.popup"                      = { bg = "base2" }
    "ui.popup.border"               = { fg = "blue" }

    # ── Statusline ──
    "ui.statusline"                 = { fg = "base00", bg = "base2" }
    "ui.statusline.inactive"        = { fg = "base1",  bg = "base2" }
    "ui.statusline.normal"          = { fg = "light_bg", bg = "blue",   modifiers = ["bold"] }
    "ui.statusline.insert"          = { fg = "light_bg", bg = "green",  modifiers = ["bold"] }
    "ui.statusline.select"          = { fg = "light_bg", bg = "yellow", modifiers = ["bold"] }
    "ui.statusline.separator"       = { fg = "base1" }
    "ui.text.modified"              = { fg = "yellow", modifiers = ["bold"] }

    [palette]
    base0      = "#839496"
    base00     = "#657b83"
    base1      = "#93a1a1"
    base2      = "#eee8d5"
    light_bg   = "#fdf6e3"
    base3      = "#fdf6e3"
    green      = "#859900"
    blue       = "#268bd2"
    cyan       = "#2aa198"
    yellow     = "#b58900"
    orange     = "#cb4b16"
    violet     = "#6c71c4"
    magenta    = "#d33682"
    red        = "#dc322f"
  '';

  programs.helix = {
    enable = true;

    settings = {
      theme = "nixotic_solarized_light";

      editor = {
        auto-pairs = true;
        auto-save = true;
        bufferline = "multiple";  # Show tabs when multiple buffers open
        color-modes = true;
        cursorline = true;
        line-number = "relative";
        rulers = [70 80 110];
        scrolloff = 13;

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
            newline = "none";
            space = "none";
            tab = "all";
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

        file-picker.hidden = true;

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };
      };

      keys.normal = {
        space.S = "workspace_symbol_picker";
        space.b = "buffer_picker";
        space.d = "diagnostics_picker";
        space.f = "file_picker";
        space.g = "changed_file_picker";
        space.q = ":quit";
        space.r = ":reload";
        space.s = "symbol_picker";
        space.space = "last_picker";
        space.w = ":write";

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
      csharp-ls            # C# / .NET
      elixir-ls            # Elixir
      jdt-language-server  # Java
      nil                  # Nix
      pyright              # Python
      rust-analyzer        # Rust
    ];
  };
}
