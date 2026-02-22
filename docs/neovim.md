# Neovim Configuration

Modern Lua-based Neovim configuration managed via Home Manager.

## Plugin Reference

### UI

| Plugin                | Description                                                          |
| --------------------- | -------------------------------------------------------------------- |
| **lualine.nvim**      | Modern statusline with Solarized Light theme. Tabline shows buffers. |
| **nvim-tree.lua**     | File explorer sidebar with git status indicators.                    |
| **nvim-web-devicons** | Filetype icons for nvim-tree and lualine.                            |
| **vim-solarized8**    | Solarized colorscheme (using light variant).                         |

### Search & Navigation

| Plugin              | Description                                       |
| ------------------- | ------------------------------------------------- |
| **telescope.nvim**  | Fuzzy finder for files, grep, buffers, help.      |
| **outline.nvim**    | LSP-powered symbols sidebar (functions, classes). |
| **nvim-treesitter** | Modern syntax highlighting and code parsing.      |

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

### LSP & Completion

| Plugin             | Description                                       |
| ------------------ | ------------------------------------------------- |
| **nvim-lspconfig** | LSP client configuration for language servers.    |
| **nvim-cmp**       | Completion engine with LSP, buffer, path sources. |
| **cmp-nvim-lsp**   | LSP source for nvim-cmp.                          |
| **cmp-buffer**     | Buffer words source for nvim-cmp.                 |
| **cmp-path**       | File path source for nvim-cmp.                    |
| **luasnip**        | Snippet engine for nvim-cmp.                      |
| **fidget.nvim**    | LSP progress indicator in corner.                 |
| **trouble.nvim**   | Pretty diagnostics list.                          |

### Configured Language Servers

| Server              | Language  |
| ------------------- | --------- |
| pyright             | Python    |
| rust-analyzer       | Rust      |
| elixir-ls           | Elixir    |
| csharp-ls           | C# / .NET |
| jdt-language-server | Java      |
| nil                 | Nix       |

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

### LSP

| Key   | Action                    |
| ----- | ------------------------- |
| `gd`  | Go to definition          |
| `gD`  | Go to declaration         |
| `gi`  | Go to implementation      |
| `gr`  | Find references           |
| `K`   | Hover documentation       |
| `,rn` | Rename symbol             |
| `,ca` | Code action               |
| `,e`  | Show diagnostic float     |
| `[d`  | Previous diagnostic       |
| `]d`  | Next diagnostic           |
| `,xx` | Toggle diagnostics list   |
| `,xd` | Toggle buffer diagnostics |

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
| Colorscheme   | Solarized8  |
| Background    | Light       |

## Auto Commands

- **Strip trailing whitespace** on save
- **Set filetype** for `.code-workspace` → JSON
