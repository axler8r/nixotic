-- UI: icons, statusline, tabline. Colours live in role_hl (init.lua).
require('mini.icons').setup()
require('mini.git').setup()
require('mini.diff').setup {
  view = {
    style = 'sign',
    signs = { add = '+', change = '~', delete = '_' },
  },
}
require('mini.statusline').setup()
require('mini.tabline').setup()

-- File explorer
require('mini.files').setup()
vim.keymap.set('n', '<F7>', function()
  if not MiniFiles.close() then MiniFiles.open() end
end, { desc = 'Toggle file explorer' })

-- Pickers
require('mini.pick').setup()
require('mini.extra').setup()
local builtin = MiniPick.builtin
vim.keymap.set('n', '<F12>', builtin.files, { desc = 'Pick files' })
vim.keymap.set('n', '<leader>f', builtin.files, { desc = 'Pick files' })
vim.keymap.set('n', '<leader>g', builtin.grep_live, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Pick buffers' })
vim.keymap.set('n', '<leader>h', builtin.help, { desc = 'Pick help tags' })
vim.keymap.set('n', '<F8>', function()
  local method = 'textDocument/documentSymbol'
  if #vim.lsp.get_clients({ bufnr = 0, method = method }) == 0 then
    vim.notify('No LSP client with document symbols', vim.log.levels.WARN)
    return
  end
  MiniExtra.pickers.lsp({ scope = 'document_symbol' })
end, { desc = 'Pick document symbols' })

-- Editing
require('mini.pairs').setup()
require('mini.align').setup()

-- Surround with tpope/vim-surround style keys (see :h MiniSurround-vim-surround-config)
require('mini.surround').setup {
  mappings = {
    add = 'ys',
    delete = 'ds',
    find = '',
    find_left = '',
    highlight = '',
    replace = 'cs',
    suffix_last = '',
    suffix_next = '',
  },
  search_method = 'cover_or_next',
}
vim.keymap.del('x', 'ys')
vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
vim.keymap.set('n', 'yss', 'ys_', { remap = true })

-- Notifications (shows LSP progress)
require('mini.notify').setup()

-- Completion and snippets. noinsert preselects the first item so <CR>
-- accepts it without an explicit selection.
vim.o.completeopt = 'menuone,noinsert'
require('mini.snippets').setup()
require('mini.completion').setup()

local map_multistep = require('mini.keymap').map_multistep
map_multistep('i', '<Tab>', { 'minisnippets_next', 'pmenu_next' })
map_multistep('i', '<S-Tab>', { 'minisnippets_prev', 'pmenu_prev' })
map_multistep('i', '<CR>', { 'pmenu_accept', 'minipairs_cr' })

-- Configure LSP servers using vim.lsp.config (nvim 0.11+)
vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
vim.lsp.config('elixirls', { cmd = { "elixir-ls" } })

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
