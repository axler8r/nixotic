# Editor Learning Guide

Resources and tutorials for the Neovim plugins and Helix configurations.

## Neovim

### LSP (Language Server Protocol)

The LSP integration provides IDE-like features: autocompletion, go-to-definition,
diagnostics, and code actions.

| Keybinding   | Action              |
| ------------ | ------------------- |
| `gd`         | Go to definition    |
| `gD`         | Go to declaration   |
| `gi`         | Go to implementation|
| `gr`         | Find references     |
| `K`          | Hover documentation |
| `,rn`        | Rename symbol       |
| `,ca`        | Code action         |
| `,e`         | Show diagnostic     |
| `[d` / `]d`  | Prev/next diagnostic|

**Tutorials:**
- [nvim-lspconfig README](https://github.com/neovim/nvim-lspconfig) — Setup and configuration
- [TJ DeVries: LSP Basics](https://www.youtube.com/watch?v=puWgHa7k3SY) — Video walkthrough
- `:help lsp` — Built-in Neovim documentation

### Completion (nvim-cmp)

Autocompletion with multiple sources: LSP, buffer words, file paths, snippets.

| Keybinding   | Action                    |
| ------------ | ------------------------- |
| `<C-Space>`  | Trigger completion        |
| `<Tab>`      | Next item / expand snippet|
| `<S-Tab>`    | Previous item             |
| `<CR>`       | Confirm selection         |
| `<C-e>`      | Abort completion          |
| `<C-b/f>`    | Scroll docs               |

**Tutorials:**
- [nvim-cmp Wiki](https://github.com/hrsh7th/nvim-cmp/wiki) — Configuration examples
- [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) — Reference config

### Snippets (LuaSnip)

Snippet engine for code templates. Tab/S-Tab jumps between placeholders.

**Tutorials:**
- [LuaSnip Basics](https://github.com/L3MON4D3/LuaSnip#keymaps) — Keymap setup
- [TJ DeVries: LuaSnip](https://www.youtube.com/watch?v=Dn800rlPIho) — Video tutorial

### Telescope

Fuzzy finder for files, grep, buffers, and more.

| Keybinding | Action           |
| ---------- | ---------------- |
| `F12`      | Find files       |
| `,f`       | Find files       |
| `,g`       | Live grep        |
| `,b`       | List buffers     |
| `,h`       | Search help tags |

**Inside Telescope:**
- `<C-n/p>` — Navigate results
- `<C-x>` — Open in horizontal split
- `<C-v>` — Open in vertical split
- `<C-t>` — Open in new tab
- `<Esc>` — Close

**Tutorials:**
- [Telescope README](https://github.com/nvim-telescope/telescope.nvim)
- `:Telescope help_tags` then search "telescope" — Built-in help

### Trouble (Diagnostics)

Better diagnostics list showing errors, warnings across the workspace.

| Keybinding | Action                    |
| ---------- | ------------------------- |
| `,xx`      | Toggle diagnostics window |
| `,xd`      | Buffer diagnostics only   |

**Tutorials:**
- [Trouble.nvim README](https://github.com/folke/trouble.nvim)

### nvim-tree (File Explorer)

| Keybinding | Action           |
| ---------- | ---------------- |
| `F7`       | Toggle file tree |

**Inside nvim-tree:**
- `<CR>` — Open file/expand folder
- `a` — Create new file
- `d` — Delete
- `r` — Rename
- `c` / `p` — Copy / Paste
- `R` — Refresh
- `g?` — Show help

**Tutorials:**
- [nvim-tree README](https://github.com/nvim-tree/nvim-tree.lua)

### Symbols Outline

LSP-powered symbols sidebar (functions, classes, variables).

| Keybinding | Action                |
| ---------- | --------------------- |
| `F8`       | Toggle symbols outline|

**Tutorials:**
- [outline.nvim README](https://github.com/hedyhli/outline.nvim)

### Gitsigns

Git integration in the gutter.

| Keybinding | Action (inside gitsigns)    |
| ---------- | --------------------------- |
| `]c`       | Next hunk                   |
| `[c`       | Previous hunk               |

**Tutorials:**
- [Gitsigns README](https://github.com/lewis6991/gitsigns.nvim)
- `:Gitsigns` — See available commands

### vim-surround

Manipulate surrounding characters.

| Command  | Description                   |
| -------- | ----------------------------- |
| `cs"'`   | Change surrounding `"` to `'` |
| `ds"`    | Delete surrounding `"`        |
| `ysiw)`  | Wrap word in `()`             |
| `yss"`   | Wrap entire line in `"`       |
| `S"` (v) | Surround selection with `"`   |

**Tutorials:**
- [vim-surround README](https://github.com/tpope/vim-surround)
- `:help surround`

### EasyAlign

Align text by delimiter.

| Keybinding | Action                        |
| ---------- | ----------------------------- |
| `ga`       | Start EasyAlign (normal/visual)|

**Examples:**
- `gaip=` — Align paragraph by `=`
- Visual select, then `ga|` — Align by `|`

**Tutorials:**
- [vim-easy-align README](https://github.com/junegunn/vim-easy-align)

---

## Helix

Helix uses Kakoune-style "selection-first" editing: select text, then act on it.

### Modal Editing: Helix vs Vim

| Concept        | Vim              | Helix                    |
| -------------- | ---------------- | ------------------------ |
| Delete word    | `dw` (verb-noun) | `wd` (select, then verb) |
| Change word    | `cw`             | `wc`                     |
| Yank line      | `yy`             | `xy` (select line, yank) |
| Delete to EOL  | `D`              | `vld` or `gld`           |

**Key insight:** In Helix, you see what you're about to act on before acting.

### Essential Helix Keybindings

**Movement:**
| Key       | Action                    |
| --------- | ------------------------- |
| `w/b/e`   | Word forward/back/end     |
| `f/t`     | Find/till character       |
| `gg/ge`   | Go to start/end of file   |
| `gl/gh`   | Go to line end/start      |
| `%`       | Go to matching bracket    |

**Selection:**
| Key       | Action                    |
| --------- | ------------------------- |
| `x`       | Select line               |
| `X`       | Extend line selection     |
| `s`       | Select within selection   |
| `S`       | Split selection           |
| `;`       | Collapse to cursor        |
| `Alt-;`   | Flip selection direction  |

**Editing:**
| Key       | Action                    |
| --------- | ------------------------- |
| `d`       | Delete selection          |
| `c`       | Change selection          |
| `y`       | Yank selection            |
| `p/P`     | Paste after/before        |
| `u/U`     | Undo/redo                 |
| `>`/`<`   | Indent/dedent             |

**LSP:**
| Key       | Action                    |
| --------- | ------------------------- |
| `gd`      | Go to definition          |
| `gr`      | Go to references          |
| `Space-s` | Symbol picker             |
| `Space-a` | Code action               |
| `Space-r` | Rename                    |
| `Space-k` | Hover docs                |

### Custom Keybindings (from config)

| Key       | Action                    |
| --------- | ------------------------- |
| `Space-w` | Write file                |
| `Space-q` | Quit                      |
| `Space-f` | File picker               |
| `Space-b` | Buffer picker             |
| `Space-s` | Symbol picker             |
| `Space-g` | Changed file picker       |
| `Space-d` | Diagnostics picker        |
| `Alt-,/.` | Previous/next buffer      |
| `]g/[g`   | Next/prev git change      |
| `Ctrl-hjkl` | Navigate splits         |
| `jk`      | Exit insert mode (quick)  |

### Surround in Helix

| Key       | Action                    |
| --------- | ------------------------- |
| `ms`      | Surround selection        |
| `md`      | Delete surround           |
| `mr`      | Replace surround          |

### Tutorials

- [Helix Tutor](https://github.com/helix-editor/helix/wiki/Helix-Tutor) — Interactive tutorial
- [Helix Documentation](https://docs.helix-editor.com/) — Official docs
- [Helix Keymap](https://docs.helix-editor.com/keymap.html) — Full keybinding reference
- `:tutor` inside Helix — Built-in tutorial
- [ThePrimeagen: Helix](https://www.youtube.com/watch?v=xHebvTGOdH8) — Video overview

### Practice Workflow

1. Run `:tutor` in Helix to learn basics
2. Practice selection-first: `w` to select word, then `d` to delete
3. Use `Space-f` and `Space-b` for file/buffer navigation
4. Use `gd` and `gr` for code navigation (requires LSP)

---

## Recommended Learning Order

### Week 1: Navigation
1. Telescope (`F12`, `,f`, `,g`, `,b`)
2. nvim-tree (`F7`)
3. Helix file/buffer pickers (`Space-f`, `Space-b`)

### Week 2: LSP
1. Neovim: `gd`, `gr`, `K`, `,ca`
2. Helix: `gd`, `gr`, `Space-a`, `Space-k`
3. Diagnostics: `]d`/`[d` in Neovim, `]g`/`[g` in Helix

### Week 3: Completion & Editing
1. nvim-cmp: `<Tab>`, `<C-Space>`, `<CR>`
2. vim-surround: `cs`, `ds`, `ys`
3. Helix surround: `ms`, `md`, `mr`

### Week 4: Advanced
1. Telescope grep workflows
2. Trouble diagnostics
3. Helix multiple selections (`s`, `S`, `C`)
