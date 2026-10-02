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
-- Names match docs/colour-token-taxonomy.md (Appendix A) for readability.
local role_hl = {
  Comment = { fg = '#839496', italic = true },
  SpecialComment = { fg = '#839496', italic = true },
  Operator = { fg = '#839496' },
  Delimiter = { fg = '#839496' },

  Keyword = { fg = '#859900', bold = true },
  Conditional = { fg = '#859900', bold = true },
  Repeat = { fg = '#859900', bold = true },
  Statement = { fg = '#859900', bold = true },
  StorageClass = { fg = '#859900', bold = true },

  Identifier = { fg = '#268bd2' },
  Constant = { fg = '#268bd2' },
  Character = { fg = '#2aa198' },
  Number = { fg = '#2aa198' },
  Boolean = { fg = '#2aa198' },
  Float = { fg = '#2aa198' },
  String = { fg = '#2aa198' },
  Special = { fg = '#6c71c4' },
  SpecialChar = { fg = '#6c71c4' },

  Type = { fg = '#b58900' },
  Structure = { fg = '#b58900' },
  Typedef = { fg = '#b58900' },
  Constructor = { fg = '#b58900' },

  Function = { fg = '#cb4b16', italic = true },

  Include = { fg = '#d33682' },
  Macro = { fg = '#d33682' },
  PreProc = { fg = '#d33682' },
  Define = { fg = '#d33682' },

  DiagnosticError = { fg = '#dc322f' },
  DiagnosticWarn = { fg = '#cb4b16' },
  DiagnosticInfo = { fg = '#2aa198' },

  ['@comment'] = { fg = '#839496', italic = true },
  ['@comment.documentation'] = { fg = '#839496', italic = true },
  ['@keyword'] = { fg = '#859900', bold = true },
  ['@keyword.import'] = { fg = '#d33682' },
  ['@keyword.directive'] = { fg = '#d33682' },
  ['@keyword.directive.define'] = { fg = '#d33682' },
  ['@variable'] = { fg = '#268bd2' },
  ['@variable.member'] = { fg = '#268bd2' },
  ['@variable.builtin'] = { fg = '#268bd2' },
  ['@constant'] = { fg = '#268bd2' },
  ['@constant.builtin'] = { fg = '#268bd2' },
  ['@number'] = { fg = '#2aa198' },
  ['@boolean'] = { fg = '#2aa198' },
  ['@string'] = { fg = '#2aa198' },
  ['@string.escape'] = { fg = '#6c71c4' },
  ['@string.special'] = { fg = '#6c71c4' },
  ['@string.regexp'] = { fg = '#6c71c4' },
  ['@type'] = { fg = '#b58900' },
  ['@type.builtin'] = { fg = '#b58900' },
  ['@constructor'] = { fg = '#b58900' },
  ['@function'] = { fg = '#cb4b16', italic = true },
  ['@function.method'] = { fg = '#cb4b16', italic = true },
  ['@function.builtin'] = { fg = '#cb4b16', italic = true },
  ['@attribute'] = { fg = '#d33682' },
  ['@module'] = { fg = '#d33682' },
  ['@module.builtin'] = { fg = '#d33682' },
  ['@operator'] = { fg = '#839496' },
  ['@punctuation'] = { fg = '#839496' },

  -- Markup (Appendix A.1)
  Tag = { fg = '#859900', bold = true },
  htmlArg = { fg = '#268bd2' },
  xmlAttrib = { fg = '#268bd2' },
  htmlString = { fg = '#2aa198' },
  xmlString = { fg = '#2aa198' },
  htmlSpecialChar = { fg = '#6c71c4' },
  xmlEntity = { fg = '#6c71c4' },
  htmlPreProc = { fg = '#d33682' },
  xmlProcessing = { fg = '#d33682' },

  -- Diff (Appendix A.1)
  DiffAdd = { fg = '#859900' },
  DiffDelete = { fg = '#dc322f' },
  DiffChange = { fg = '#b58900' },
  DiffText = { fg = '#2aa198' },

  -- Diagnostics — add hint (Appendix A.1)
  DiagnosticHint = { fg = '#2aa198' },

  -- UI chrome (Appendix A.1)
  LineNr = { fg = '#839496' },
  CursorLineNr = { fg = '#657b83', bold = true },
  Cursor = { fg = '#657b83' },
  CursorIM = { fg = '#657b83' },
  CursorLine = { bg = '#eee8d5' },
  Visual = { bg = '#eee8d5' },
  MatchParen = { fg = '#b58900', bold = true },
  IncSearch = { fg = '#b58900', bold = true },
  CurSearch = { fg = '#b58900', bold = true },
  Search = { fg = '#93a1a1' },
  LspInlayHint = { fg = '#93a1a1', italic = true },
  NormalFloat = { bg = '#eee8d5' },
  FloatBorder = { fg = '#268bd2' },

  -- Treesitter additions (Appendix A.2)
  ['@keyword.control'] = { fg = '#859900', bold = true },
  ['@keyword.storage'] = { fg = '#859900', bold = true },
  ['@keyword.return'] = { fg = '#859900', bold = true },
  ['@variable.parameter'] = { fg = '#268bd2' },
  ['@number.float'] = { fg = '#2aa198' },
  ['@function.call'] = { fg = '#cb4b16', italic = true },
  ['@punctuation.delimiter'] = { fg = '#839496' },
  ['@punctuation.bracket'] = { fg = '#839496' },
  ['@tag'] = { fg = '#859900', bold = true },
  ['@tag.builtin'] = { fg = '#859900', bold = true },
  ['@tag.attribute'] = { fg = '#268bd2' },
  ['@string.special.symbol'] = { fg = '#6c71c4' },
  ['@diff.plus'] = { fg = '#859900' },
  ['@diff.minus'] = { fg = '#dc322f' },
  ['@diff.delta'] = { fg = '#b58900' },
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
