{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = with pkgs.vimPlugins; [
      # Colorscheme
      vim-solarized8

      # UI
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup {
            options = {
              theme = 'solarized_light',
              section_separators = { left = "", right = "" },
              component_separators = { left = "", right = "" },
            },
            sections = {
              lualine_a = { 'mode' },
              lualine_b = { 'branch', 'diff', 'diagnostics' },
              lualine_c = { 'filename' },
              lualine_x = { 'encoding', 'fileformat', 'filetype' },
              lualine_y = { 'progress' },
              lualine_z = { 'location' }
            },
            tabline = {
              lualine_a = { 'buffers' },
              lualine_z = { 'tabs' }
            },
          }
        '';
      }
      nvim-web-devicons

      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require('nvim-tree').setup {
            view = { width = 35 },
            renderer = { icons = { show = { git = true } } },
          }
          vim.keymap.set('n', '<F7>', ':NvimTreeToggle<CR>', { silent = true })
        '';
      }

      # Telescope (replaces fzf.vim)
      plenary-nvim
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          local telescope = require('telescope')
          local builtin = require('telescope.builtin')
          telescope.setup {
            defaults = {
              file_ignore_patterns = { "node_modules", ".git/" },
            },
          }
          vim.keymap.set('n', '<F12>', builtin.find_files, {})
          vim.keymap.set('n', '<leader>f', builtin.find_files, {})
          vim.keymap.set('n', '<leader>g', builtin.live_grep, {})
          vim.keymap.set('n', '<leader>b', builtin.buffers, {})
          vim.keymap.set('n', '<leader>h', builtin.help_tags, {})
        '';
      }

      # Git
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
          require('gitsigns').setup {
            signs = {
              add          = { text = '│' },
              change       = { text = '│' },
              delete       = { text = '_' },
              topdelete    = { text = '‾' },
              changedelete = { text = '~' },
            },
          }
        '';
      }
      vim-fugitive

      # Treesitter (syntax highlighting) - grammars auto-activate for supported files
      nvim-treesitter.withAllGrammars

      # Symbols outline (replaces tagbar)
      {
        plugin = symbols-outline-nvim;
        type = "lua";
        config = ''
          require('symbols-outline').setup()
          vim.keymap.set('n', '<F8>', ':SymbolsOutline<CR>', { silent = true })
        '';
      }

      # Editing
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = "require('nvim-autopairs').setup {}";
      }
      vim-surround
      tabular
      {
        plugin = vim-easy-align;
        type = "lua";
        config = ''
          vim.keymap.set('x', 'ga', '<Plug>(EasyAlign)', {})
          vim.keymap.set('n', 'ga', '<Plug>(EasyAlign)', {})
        '';
      }

      # Rainbow delimiters
      rainbow-delimiters-nvim

      # Language support
      vim-toml
      vim-elixir
      vim-erlang-runtime
      vim-markdown

      # AI
      copilot-vim
    ];

    extraLuaConfig = ''
      -- Leader key
      vim.g.mapleader = ','

      -- General settings
      vim.opt.autoindent = true
      vim.opt.smartindent = true
      vim.opt.autoread = true
      vim.opt.background = 'light'
      vim.opt.colorcolumn = '70,80,110'
      vim.opt.cmdheight = 2
      vim.opt.cursorline = true
      vim.opt.expandtab = true
      vim.opt.foldenable = false  -- Don't fold by default
      vim.opt.incsearch = true
      vim.opt.laststatus = 2
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.shiftwidth = 4
      vim.opt.showmatch = true
      vim.opt.smarttab = true
      vim.opt.softtabstop = 4
      vim.opt.tabstop = 4
      vim.opt.scrolloff = 13
      vim.opt.termguicolors = true
      vim.opt.showtabline = 2

      -- Colorscheme
      vim.opt.background = 'light'
      vim.cmd('colorscheme solarized8')

      -- Strip trailing whitespace on save
      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*',
        command = [[%s/\s\+$//e]],
      })

      -- Filetypes
      vim.api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
        pattern = '*.code-workspace',
        command = 'set filetype=json',
      })

      -- Toggle spell checking
      vim.keymap.set('n', '<leader>sp', ':setlocal spell! spelllang=en<CR>', { silent = true })
      vim.keymap.set('n', '<leader>ts', ':setlocal spell! spelllang=en<CR>', { silent = true })
    '';

    # CLI tools for neovim plugins
    extraPackages = with pkgs; [
      tree-sitter  # For nvim-treesitter health check
    ];
  };
}
