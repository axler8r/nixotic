{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      # Colorscheme
      vim-solarized8

      # mini.nvim: statusline, tabline, files, pick, diff, git, pairs,
      # surround, align, notify, icons, completion, snippets, keymap
      mini-nvim

      # Treesitter parsers and queries; highlighting is started per buffer by
      # the FileType autocmd in files/neovim/plugins.lua
      nvim-treesitter.withAllGrammars

      # Rainbow delimiters
      rainbow-delimiters-nvim

      # Elixir/EEx indent and ftplugin; Neovim ships none. Treesitter
      # suppresses its regex syntax.
      vim-elixir

      # LSP
      nvim-lspconfig

      # Formatting
      conform-nvim

      # Linting
      {
        plugin = nvim-lint;
        type = "lua";
        config = builtins.readFile ../files/neovim/plugins.lua;
      }
    ];

    initLua = builtins.readFile ../files/neovim/init.lua;

    # CLI tools for neovim plugins
    extraPackages = with pkgs; [
      tree-sitter # For nvim-treesitter health check

      # LSP servers
      pyright # Python
      rust-analyzer # Rust
      elixir-ls # Elixir
      csharp-ls # C# / .NET
      jdt-language-server # Java
      nil # Nix

      # Markdown
      markdownlint-cli2
      prettier

      # Python
      ruff

      # C#
      csharpier
    ];
  };
}
