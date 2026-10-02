local sol_lualine = {
  normal   = { a = { fg = '#fdf6e3', bg = '#268bd2', gui = 'bold' },
               b = { fg = '#657b83', bg = '#eee8d5' },
               c = { fg = '#657b83', bg = '#eee8d5' } },
  insert   = { a = { fg = '#fdf6e3', bg = '#859900', gui = 'bold' } },
  visual   = { a = { fg = '#fdf6e3', bg = '#b58900', gui = 'bold' } },
  replace  = { a = { fg = '#fdf6e3', bg = '#dc322f', gui = 'bold' } },
  command  = { a = { fg = '#fdf6e3', bg = '#cb4b16', gui = 'bold' } },
  inactive = { a = { fg = '#93a1a1', bg = '#eee8d5' },
               b = { fg = '#93a1a1', bg = '#eee8d5' },
               c = { fg = '#93a1a1', bg = '#eee8d5' } },
}
require('lualine').setup {
  options = {
    theme = sol_lualine,
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

require('nvim-tree').setup {
  view = { width = 35 },
  renderer = { icons = { show = { git = true } } },
}
vim.keymap.set('n', '<F7>', ':NvimTreeToggle<CR>', { silent = true })

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

require('gitsigns').setup {
  signs = {
    add          = { text = '+' },
    change       = { text = '~' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '±' },
  },
}

require('outline').setup()
vim.keymap.set('n', '<F8>', ':Outline<CR>', { silent = true })

require('nvim-autopairs').setup {}
vim.keymap.set('x', 'ga', '<Plug>(EasyAlign)', {})
vim.keymap.set('n', 'ga', '<Plug>(EasyAlign)', {})

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

require('fidget').setup {}
require('trouble').setup {}
vim.keymap.set('n', '<leader>xx', ':Trouble diagnostics toggle<CR>', { silent = true })
vim.keymap.set('n', '<leader>xd', ':Trouble diagnostics toggle filter.buf=0<CR>', { silent = true })

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

require('lint').linters_by_ft = {
  markdown = { 'markdownlint' },
  python   = { 'ruff' },
}
vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
  callback = function()
    require('lint').try_lint()
  end,
})
