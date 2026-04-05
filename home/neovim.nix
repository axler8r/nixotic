{ config, pkgs, ... }:

let
  solarized = {
    lightBackground = "#fdf6e3";
    lightBackgroundContrast = "#eee8d5";
    lightestAccent = "#93a1a1";
    lightAccent = "#839496";
    darkAccent = "#657b83";
    darkestAccent = "#586e75";
    darkBackgroundContrast = "#073642";
    darkBackground = "#002b36";

    red = "#dc322f";
    orange = "#cb4b16";
    yellow = "#b58900";
    green = "#859900";
    cyan = "#2aa198";
    blue = "#268bd2";
    violet = "#6c71c4";
    magenta = "#d33682";
  };
in
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
              add          = { text = '+' },
              change       = { text = '~' },
              delete       = { text = '_' },
              topdelete    = { text = '‾' },
              changedelete = { text = '±' },
            },
          }
        '';
      }
      vim-fugitive

      # Treesitter (syntax highlighting) - grammars auto-activate for supported files
      nvim-treesitter.withAllGrammars

      # Symbols outline (replaces tagbar)
      {
        plugin = outline-nvim;
        type = "lua";
        config = ''
          require('outline').setup()
          vim.keymap.set('n', '<F8>', ':Outline<CR>', { silent = true })
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

      # LSP
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          local capabilities = require('cmp_nvim_lsp').default_capabilities()

          -- Configure LSP servers using vim.lsp.config (nvim 0.11+)
          vim.lsp.config('pyright', { capabilities = capabilities })
          vim.lsp.config('rust_analyzer', { capabilities = capabilities })
          vim.lsp.config('elixirls', { capabilities = capabilities, cmd = { "elixir-ls" } })
          vim.lsp.config('csharp_ls', { capabilities = capabilities })
          vim.lsp.config('jdtls', { capabilities = capabilities })
          vim.lsp.config('julials', { capabilities = capabilities })
          vim.lsp.config('nil_ls', { capabilities = capabilities })

          -- Enable configured servers
          vim.lsp.enable({ 'pyright', 'rust_analyzer', 'elixirls', 'csharp_ls', 'jdtls', 'julials', 'nil_ls' })

          -- LSP keymaps
          vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
              local opts = { buffer = args.buf }
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
              vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
              vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
              vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
              vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
              vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
              vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
            end,
          })
        '';
      }

      # LSP progress indicator
      {
        plugin = fidget-nvim;
        type = "lua";
        config = "require('fidget').setup {}";
      }

      # Better diagnostics
      {
        plugin = trouble-nvim;
        type = "lua";
        config = ''
          require('trouble').setup {}
          vim.keymap.set('n', '<leader>xx', ':Trouble diagnostics toggle<CR>', { silent = true })
          vim.keymap.set('n', '<leader>xd', ':Trouble diagnostics toggle filter.buf=0<CR>', { silent = true })
        '';
      }

      # Completion
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          local cmp = require('cmp')
          local luasnip = require('luasnip')

          cmp.setup {
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-b>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<C-e>'] = cmp.mapping.abort(),
              ['<CR>'] = cmp.mapping.confirm({ select = true }),
              ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' }),
              ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
            }, {
              { name = 'buffer' },
              { name = 'path' },
            }),
          }
        '';
      }

      # Formatting
      {
        plugin = conform-nvim;
        type = "lua";
        config = ''
          require('conform').setup {
            formatters_by_ft = {
              markdown = { 'prettier' },
              python   = { 'ruff_format' },
              cs       = { 'csharpier' },
            },
            format_on_save = {
              timeout_ms = 500,
              lsp_format = 'fallback',
            },
          }
        '';
      }

      # Linting
      {
        plugin = nvim-lint;
        type = "lua";
        config = ''
          require('lint').linters_by_ft = {
            markdown = { 'markdownlint' },
            python   = { 'ruff' },
          }
          vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
            callback = function()
              require('lint').try_lint()
            end,
          })
        '';
      }

      # AI
      copilot-vim
    ];

    initLua = ''
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

      -- Enforce Nixotic syntax role palette regardless of colorscheme defaults.
      -- Names match `docs/theme.md` for readability.
      local role_hl = {
        Comment = { fg = '${solarized.lightAccent}', italic = true },
        SpecialComment = { fg = '${solarized.lightAccent}', italic = true },
        Operator = { fg = '${solarized.lightAccent}' },
        Delimiter = { fg = '${solarized.lightAccent}' },

        Keyword = { fg = '${solarized.green}', bold = true },
        Conditional = { fg = '${solarized.green}', bold = true },
        Repeat = { fg = '${solarized.green}', bold = true },
        Statement = { fg = '${solarized.green}', bold = true },
        StorageClass = { fg = '${solarized.green}', bold = true },

        Identifier = { fg = '${solarized.blue}' },
        Constant = { fg = '${solarized.blue}' },
        Character = { fg = '${solarized.cyan}' },
        Number = { fg = '${solarized.cyan}' },
        Boolean = { fg = '${solarized.cyan}' },
        Float = { fg = '${solarized.cyan}' },
        String = { fg = '${solarized.cyan}' },
        Special = { fg = '${solarized.violet}' },
        SpecialChar = { fg = '${solarized.violet}' },

        Type = { fg = '${solarized.yellow}' },
        Structure = { fg = '${solarized.yellow}' },
        Typedef = { fg = '${solarized.yellow}' },
        Constructor = { fg = '${solarized.yellow}' },

        Function = { fg = '${solarized.orange}', italic = true },

        Include = { fg = '${solarized.magenta}' },
        Macro = { fg = '${solarized.magenta}' },
        PreProc = { fg = '${solarized.magenta}' },
        Define = { fg = '${solarized.magenta}' },

        DiagnosticError = { fg = '${solarized.red}' },
        DiagnosticWarn = { fg = '${solarized.orange}' },
        DiagnosticInfo = { fg = '${solarized.cyan}' },

        ['@comment'] = { fg = '${solarized.lightAccent}', italic = true },
        ['@comment.documentation'] = { fg = '${solarized.lightAccent}', italic = true },
        ['@keyword'] = { fg = '${solarized.green}', bold = true },
        ['@keyword.import'] = { fg = '${solarized.magenta}' },
        ['@keyword.directive'] = { fg = '${solarized.magenta}' },
        ['@keyword.directive.define'] = { fg = '${solarized.magenta}' },
        ['@variable'] = { fg = '${solarized.blue}' },
        ['@variable.member'] = { fg = '${solarized.blue}' },
        ['@variable.builtin'] = { fg = '${solarized.blue}' },
        ['@constant'] = { fg = '${solarized.blue}' },
        ['@constant.builtin'] = { fg = '${solarized.blue}' },
        ['@number'] = { fg = '${solarized.cyan}' },
        ['@boolean'] = { fg = '${solarized.cyan}' },
        ['@string'] = { fg = '${solarized.cyan}' },
        ['@string.escape'] = { fg = '${solarized.violet}' },
        ['@string.special'] = { fg = '${solarized.violet}' },
        ['@string.regexp'] = { fg = '${solarized.violet}' },
        ['@type'] = { fg = '${solarized.yellow}' },
        ['@type.builtin'] = { fg = '${solarized.yellow}' },
        ['@constructor'] = { fg = '${solarized.yellow}' },
        ['@function'] = { fg = '${solarized.orange}', italic = true },
        ['@function.method'] = { fg = '${solarized.orange}', italic = true },
        ['@function.builtin'] = { fg = '${solarized.orange}', italic = true },
        ['@attribute'] = { fg = '${solarized.magenta}' },
        ['@module'] = { fg = '${solarized.magenta}' },
        ['@module.builtin'] = { fg = '${solarized.magenta}' },
        ['@operator'] = { fg = '${solarized.lightAccent}' },
        ['@punctuation'] = { fg = '${solarized.lightAccent}' },
      }

      for group, opts in pairs(role_hl) do
        vim.api.nvim_set_hl(0, group, opts)
      end

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
