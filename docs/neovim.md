# Neovim Configuration

Modern Lua-based Neovim configuration managed via Home Manager.

## Migration from vim-plug

The previous vim-plug setup (from `.duplic8r`) has been migrated to declarative
Nix-managed plugins using `programs.neovim.plugins`. All plugins are now
installed via nixpkgs.

### Key Changes

| Old (vim-plug)         | New (Nix + Lua)         |
| ---------------------- | ----------------------- |
| `init.vim` (Vimscript) | `extraLuaConfig` (Lua)  |
| lightline.vim          | lualine.nvim            |
| nerdtree               | nvim-tree.lua           |
| fzf.vim                | telescope.nvim          |
| vim-gitgutter          | gitsigns.nvim           |
| tagbar                 | symbols-outline.nvim    |
| vim-rainbow            | rainbow-delimiters.nvim |
| vim-solarized8         | palenight-vim           |
| Manual syntax          | nvim-treesitter         |

## Plugin Reference

### UI

| Plugin                | Description                                                         |
| --------------------- | ------------------------------------------------------------------- |
| **lualine.nvim**      | Modern statusline with Palenight theme. Tabline shows open buffers. |
| **nvim-tree.lua**     | File explorer sidebar with git status indicators.                   |
| **nvim-web-devicons** | Filetype icons for nvim-tree and lualine.                           |
| **palenight-vim**     | Material Palenight colorscheme.                                     |

### Search & Navigation

| Plugin                   | Description                                       |
| ------------------------ | ------------------------------------------------- |
| **telescope.nvim**       | Fuzzy finder for files, grep, buffers, help.      |
| **symbols-outline.nvim** | LSP-powered symbols sidebar (functions, classes). |
| **nvim-treesitter**      | Modern syntax highlighting and code parsing.      |

### Git Integration

| Plugin            | Description                                             |
| ----------------- | ------------------------------------------------------- |
| **gitsigns.nvim** | Git diff signs in the gutter (added, changed, deleted). |
| **vim-fugitive**  | Git commands (`:Git`, `:Gblame`, `:Gdiff`).             |

### Editing

| Plugin                      | Description                                          |
| --------------------------- | ---------------------------------------------------- |
| **nvim-autopairs**          | Auto-close brackets, quotes, and parentheses.        |
| **vim-surround**            | Manipulate surrounding characters (`cs"'`, `ysiw)`). |
| **vim-easy-align**          | Align text by delimiter.                             |
| **tabular**                 | Align text in columns.                               |
| **rainbow-delimiters.nvim** | Colorize matching bracket pairs.                     |

### Language Support

| Plugin                 | Description                    |
| ---------------------- | ------------------------------ |
| **vim-toml**           | TOML syntax.                   |
| **vim-elixir**         | Elixir syntax and indentation. |
| **vim-erlang-runtime** | Erlang syntax.                 |
| **vim-markdown**       | Markdown syntax and folding.   |

### AI

| Plugin          | Description                 |
| --------------- | --------------------------- |
| **copilot.vim** | GitHub Copilot suggestions. |

## Keybindings

### Leader Key

The leader key is `,` (comma).

### File Navigation

| Key   | Action                       |
| ----- | ---------------------------- |
| `F7`  | Toggle file tree (nvim-tree) |
| `F8`  | Toggle symbols outline       |
| `F12` | Find files (Telescope)       |
| `,f`  | Find files (Telescope)       |
| `,g`  | Live grep (search in files)  |
| `,b`  | List buffers                 |
| `,h`  | Search help tags             |

### Editing

| Key   | Action                            |
| ----- | --------------------------------- |
| `ga`  | EasyAlign (visual mode or motion) |
| `,sp` | Toggle spell checking             |
| `,ts` | Toggle spell checking (alias)     |

### vim-surround Examples

| Command | Description                   |
| ------- | ----------------------------- |
| `cs"'`  | Change surrounding `"` to `'` |
| `ds"`   | Delete surrounding `"`        |
| `ysiw)` | Wrap word in `()`             |
| `yss"`  | Wrap entire line in `"`       |

## Configuration Location

The configuration is in [home/neovim.nix](../home/neovim.nix):

- `plugins` — Declarative plugin list with per-plugin Lua config
- `extraLuaConfig` — Global settings, keybindings, autocmds

## Editor Settings

| Setting       | Value       |
| ------------- | ----------- |
| Tab width     | 4 spaces    |
| Color column  | 70, 80, 110 |
| Scroll offset | 13 lines    |
| Line numbers  | Relative    |
| Colorscheme   | Palenight   |

## Auto Commands

- **Strip trailing whitespace** on save
- **Set filetype** for `.code-workspace` → JSON
