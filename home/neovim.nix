{ lib, pkgs, ... }:

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

      # UI
      lualine-nvim
      nvim-web-devicons

      nvim-tree-lua

      # Telescope (replaces fzf.vim)
      plenary-nvim
      telescope-nvim

      # Git
      gitsigns-nvim
      vim-fugitive

      # Treesitter (syntax highlighting) - grammars auto-activate for supported files
      nvim-treesitter.withAllGrammars

      # Symbols outline (replaces tagbar)
      outline-nvim

      # Editing
      nvim-autopairs
      vim-surround
      tabular
      vim-easy-align

      # Rainbow delimiters
      rainbow-delimiters-nvim

      # Language support
      vim-toml
      vim-elixir
      vim-erlang-runtime
      vim-markdown

      # LSP
      nvim-lspconfig

      # LSP progress indicator
      fidget-nvim

      # Better diagnostics
      trouble-nvim

      # Completion
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      nvim-cmp

      # Formatting
      conform-nvim

      # Linting
      nvim-lint
    ];

    initLua = lib.mkMerge [
      (builtins.readFile ../files/neovim/init.lua)
      (lib.mkAfter (builtins.readFile ../files/neovim/plugins.lua))
    ];

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
