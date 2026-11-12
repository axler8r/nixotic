# Colour Preferences

## Introduction

My preferred colours for coding and terminal work.

> [!NOTE] The Goal is Consistency
>
> The same kind of token should look the same wherever practical. This document
> is the single source of truth. All tool configurations derive from it.

## Rules

1. Stylix manages desktop chrome only: GNOME shell, GTK, fonts, cursor, and
   wallpaper.
2. Base16 sucks, so I use my own Solarized palette and syntax colours.
3. Tools use manual Solarized themes, based on my palette.
4. Use Solarized Light.

## Palette

I gave the colours human-friendly names, but the Solarized names are included
for reference.

### Tonal Colours

| My Name                   | Solarized Name | Hex      |
| ------------------------- | -------------- | -------- |
| Light Background          | base3          | `fdf6e3` |
| Light Background Contrast | base2          | `eee8d5` |
| Lightest Accent           | base1          | `93a1a1` |
| Light Accent              | base0          | `839496` |
| Dark Accent               | base00         | `657b83` |
| Darkest Accent            | base01         | `586e75` |
| Dark Background Contrast  | base02         | `073642` |
| Dark Background           | base03         | `002b36` |

### Chromatic Colours

These are the accent colours used for syntax and diagnostics.

| My Name | Solarized Name | Hex      |
| ------- | -------------- | -------- |
| Red     | red            | `dc322f` |
| Orange  | orange         | `cb4b16` |
| Yellow  | yellow         | `b58900` |
| Green   | green          | `859900` |
| Cyan    | cyan           | `2aa198` |
| Blue    | blue           | `268bd2` |
| Violet  | violet         | `6c71c4` |
| Magenta | magenta        | `d33682` |

## Canonical Token Taxonomy

This is the authoritative token table. Every tool appendix maps its
tool-specific names to the slugs in the `Token Slug` column.

### Code — Core

| Token Slug            | Description                                         | Colour               | Style    | Hex      |
| --------------------- | --------------------------------------------------- | -------------------- | -------- | -------- |
| `code.keyword`        | Keywords: `if`, `for`, `return`, `def`, `match`, …  | green                | **Bold** | `859900` |
| `code.variable`       | Variables, identifiers, parameters                  | blue                 | Normal   | `268bd2` |
| `code.constant`       | Named constants (`MY_CONST`, `nil`, `None`, …)      | blue                 | Normal   | `268bd2` |
| `code.type`           | Classes, types, structs, interfaces, enums          | yellow               | Normal   | `b58900` |
| `code.literal.string` | String literals                                     | cyan                 | Normal   | `2aa198` |
| `code.literal.number` | Integer, float, and numeric literals                | cyan                 | Normal   | `2aa198` |
| `code.literal.bool`   | Boolean literals (`true`, `false`)                  | cyan                 | Normal   | `2aa198` |
| `code.literal.null`   | Null/nil/nothing literals                           | cyan                 | Normal   | `2aa198` |
| `code.function`       | Function, procedure, and method names               | orange               | _Italic_ | `cb4b16` |
| `code.import`         | Import, include, use, require, namespace directives | magenta              | Normal   | `d33682` |
| `code.macro`          | Macros, pragmas, annotations, attributes            | magenta              | Normal   | `d33682` |
| `code.interpolation`  | String interpolations, escape sequences             | violet               | Normal   | `6c71c4` |
| `code.regex`          | Regular expression literals                         | violet               | Normal   | `6c71c4` |
| `code.comment`        | Inline and block comments                           | Light Accent (base0) | _Italic_ | `839496` |
| `code.doc_comment`    | Documentation comments (`///`, `/**`, `##`)         | Light Accent (base0) | _Italic_ | `839496` |
| `code.operator`       | Operators: `+`, `->`, `=>`, `::`, …                 | Light Accent (base0) | Normal   | `839496` |
| `code.punctuation`    | Delimiters, brackets, commas, semicolons            | Light Accent (base0) | Normal   | `839496` |

> [!NOTE] Conventions
>
> - `code.literal.*` types intentionally share cyan — all are value literals.
> - `code.constant` is blue (naming role) not cyan (literal role): a named
>   constant is an identifier, not a literal value.
> - `code.comment` and `code.doc_comment` intentionally share base0/italic.
> - `code.import` and `code.macro` intentionally share magenta.

### Code — Diagnostics

| Token Slug     | Description                | Colour | Style  | Hex      |
| -------------- | -------------------------- | ------ | ------ | -------- |
| `diag.error`   | Error severity             | red    | Normal | `dc322f` |
| `diag.warning` | Warning severity           | orange | Normal | `cb4b16` |
| `diag.info`    | Info / hint severity       | cyan   | Normal | `2aa198` |
| `diag.hint`    | Hint / suggestion severity | cyan   | Normal | `2aa198` |

### Markup — HTML / XML

Tags are the structural control tokens of markup — they play the keyword role.
Attributes name things — they play the variable role.

| Token Slug         | Description                                       | Colour               | Style    | Hex      |
| ------------------ | ------------------------------------------------- | -------------------- | -------- | -------- |
| `markup.tag`       | Element tags: `<div>`, `<root>`, `</span>`        | green                | **Bold** | `859900` |
| `markup.attribute` | Attribute names: `class=`, `id=`, `href=`         | blue                 | Normal   | `268bd2` |
| `markup.value`     | Attribute values: `"foo"`, `"bar"`                | cyan                 | Normal   | `2aa198` |
| `markup.entity`    | HTML/XML entities: `&amp;`, `&lt;`                | violet               | Normal   | `6c71c4` |
| `markup.doctype`   | Doctypes and processing instructions: `<?xml …?>` | magenta              | Normal   | `d33682` |
| `markup.comment`   | `<!-- … -->`                                      | Light Accent (base0) | _Italic_ | `839496` |

### Data — JSON / JSONC

| Token Slug         | Description                     | Colour               | Style    | Hex      |
| ------------------ | ------------------------------- | -------------------- | -------- | -------- |
| `json.key`         | Object keys                     | blue                 | Normal   | `268bd2` |
| `json.string`      | String values                   | cyan                 | Normal   | `2aa198` |
| `json.number`      | Number values                   | cyan                 | Normal   | `2aa198` |
| `json.bool`        | `true`, `false`                 | cyan                 | Normal   | `2aa198` |
| `json.null`        | `null`                          | cyan                 | Normal   | `2aa198` |
| `json.punctuation` | `{`, `}`, `[`, `]`, `:`, `,`    | Light Accent (base0) | Normal   | `839496` |
| `json.comment`     | JSONC comments: `//`, `/* … */` | Light Accent (base0) | _Italic_ | `839496` |

### Data — YAML

| Token Slug      | Description                    | Colour               | Style    | Hex      |
| --------------- | ------------------------------ | -------------------- | -------- | -------- |
| `yaml.key`      | Mapping keys                   | blue                 | Normal   | `268bd2` |
| `yaml.string`   | Scalar string values           | cyan                 | Normal   | `2aa198` |
| `yaml.number`   | Numeric scalar values          | cyan                 | Normal   | `2aa198` |
| `yaml.bool`     | `true`, `false`, `yes`, `no`   | cyan                 | Normal   | `2aa198` |
| `yaml.null`     | `null`, `~`                    | cyan                 | Normal   | `2aa198` |
| `yaml.anchor`   | Anchors: `&name`               | magenta              | Normal   | `d33682` |
| `yaml.alias`    | Aliases: `*name`               | violet               | Normal   | `6c71c4` |
| `yaml.tag`      | Type tags: `!!str`, `!!int`    | yellow               | Normal   | `b58900` |
| `yaml.document` | Document markers: `---`, `...` | Light Accent (base0) | Normal   | `839496` |
| `yaml.comment`  | `# …`                          | Light Accent (base0) | _Italic_ | `839496` |

### Data — TOML

| Token Slug         | Description                               | Colour               | Style    | Hex      |
| ------------------ | ----------------------------------------- | -------------------- | -------- | -------- |
| `toml.header`      | Table and array-of-table headers: `[foo]` | yellow               | Normal   | `b58900` |
| `toml.key`         | Key names                                 | blue                 | Normal   | `268bd2` |
| `toml.string`      | String values                             | cyan                 | Normal   | `2aa198` |
| `toml.number`      | Integer and float values                  | cyan                 | Normal   | `2aa198` |
| `toml.bool`        | `true`, `false`                           | cyan                 | Normal   | `2aa198` |
| `toml.date`        | Datetime values                           | cyan                 | Normal   | `2aa198` |
| `toml.punctuation` | `=`, `.`, `[`, `]`, `,`                   | Light Accent (base0) | Normal   | `839496` |
| `toml.comment`     | `# …`                                     | Light Accent (base0) | _Italic_ | `839496` |

### Stylesheet — CSS / SCSS / Less

At-rules play the import/pragma role. Selectors name types. Properties name
attributes within a type namespace — closer to variable than to function.

| Token Slug        | Description                                       | Colour               | Style    | Hex      |
| ----------------- | ------------------------------------------------- | -------------------- | -------- | -------- |
| `css.selector`    | Selectors: `.btn`, `#id`, `h1`, `::before`        | yellow               | Normal   | `b58900` |
| `css.property`    | Property names: `color`, `margin`, `display`      | blue                 | Normal   | `268bd2` |
| `css.value`       | Property values: `red`, `12px`, `bold`, `inherit` | cyan                 | Normal   | `2aa198` |
| `css.at_rule`     | At-rules: `@media`, `@import`, `@keyframes`       | magenta              | Normal   | `d33682` |
| `css.function`    | Functions: `calc()`, `var()`, `rgb()`             | orange               | _Italic_ | `cb4b16` |
| `css.variable`    | Custom properties / SCSS vars: `--foo`, `$bar`    | blue                 | Normal   | `268bd2` |
| `css.punctuation` | `{`, `}`, `:`, `;`, `,`                           | Light Accent (base0) | Normal   | `839496` |
| `css.comment`     | `/* … */`, `//`                                   | Light Accent (base0) | _Italic_ | `839496` |

### Shell — Zsh / Bash

String literals are cyan (literals), not blue (variables). Variable expansions
are blue (variable role). Process/command substitutions are violet
(interpolation role). Commands and builtins are green/bold — they are the
shell's keywords.

| Token Slug              | Description                                      | Colour               | Style    | Hex      |
| ----------------------- | ------------------------------------------------ | -------------------- | -------- | -------- |
| `shell.command`         | Valid commands, builtins, functions, aliases     | green                | **Bold** | `859900` |
| `shell.keyword`         | Reserved words: `if`, `then`, `while`, `do`, …   | green                | **Bold** | `859900` |
| `shell.command_invalid` | Unknown or invalid commands                      | red                  | **Bold** | `dc322f` |
| `shell.argument`        | Options and arguments: `--foo`, `bar`            | blue                 | Normal   | `268bd2` |
| `shell.path`            | File path arguments                              | blue                 | Normal   | `268bd2` |
| `shell.variable`        | Variable expansions: `$VAR`, `${VAR}`            | blue                 | Normal   | `268bd2` |
| `shell.string`          | Quoted string literals: `"…"`, `'…'`             | cyan                 | Normal   | `2aa198` |
| `shell.interpolation`   | Process/command substitutions: `$(…)`, `` `…` `` | violet               | Normal   | `6c71c4` |
| `shell.heredoc`         | Heredoc body content                             | cyan                 | Normal   | `2aa198` |
| `shell.assign`          | Variable assignments: `FOO=bar`                  | blue                 | Normal   | `268bd2` |
| `shell.glob`            | Glob patterns: `*`, `?`, `**`                    | blue                 | Normal   | `268bd2` |
| `shell.separator`       | Separators and redirections: `\|`, `;`, `>`, `&` | Light Accent (base0) | Normal   | `839496` |
| `shell.comment`         | `# …`                                            | Light Accent (base0) | _Italic_ | `839496` |

> [!NOTE] Shell Conventions
>
> - `shell.command` and `shell.keyword` intentionally share green/**Bold**. Both
>   are executable/control tokens; the distinction is not visually useful.
> - `shell.string` is cyan (literal), not blue (variable). This is a correction
>   from earlier config which used blue for quoted arguments.

### Diff / VCS

| Token Slug         | Description                            | Colour               | Style    | Hex      |
| ------------------ | -------------------------------------- | -------------------- | -------- | -------- |
| `diff.added`       | Added lines: `+`                       | green                | Normal   | `859900` |
| `diff.deleted`     | Removed lines: `-`                     | red                  | Normal   | `dc322f` |
| `diff.changed`     | Changed / modified lines               | yellow               | Normal   | `b58900` |
| `diff.hunk`        | Hunk headers: `@@ … @@`                | cyan                 | Normal   | `2aa198` |
| `diff.file_header` | File headers: `--- a/foo`, `+++ b/foo` | Light Accent (base0) | **Bold** | `839496` |

### Editor UI Chrome

| Token Slug               | Description                       | Colour / BG                                                              | Style    |
| ------------------------ | --------------------------------- | ------------------------------------------------------------------------ | -------- |
| `ui.fg`                  | Default foreground                | Light Accent (base0) `839496`                                            | Normal   |
| `ui.bg`                  | Default background                | Light Background `fdf6e3`                                                | —        |
| `ui.line_number`         | Gutter line numbers               | Light Accent (base0) `839496`                                            | Normal   |
| `ui.line_number_current` | Current line number               | Dark Accent (base00) `657b83`                                            | **Bold** |
| `ui.cursor`              | Cursor                            | bg: Magenta `d33682`, fg: Light Background (base3) `fdf6e3`              | **Bold** |
| `ui.cursorline`          | Current line highlight background | Light Background Contrast `eee8d5`                                       | —        |
| `ui.selection`           | Visual selection background       | bg: Dark Accent (base00) `657b83`, fg: Light Background (base3) `fdf6e3` | —        |
| `ui.match_bracket`       | Matching bracket highlight        | yellow `b58900`                                                          | **Bold** |
| `ui.search_current`      | Current search match highlight    | yellow `b58900`                                                          | **Bold** |
| `ui.search_other`        | Other search match highlights     | Lightest Accent (base1) `93a1a1`                                         | Normal   |
| `ui.inlay_hint`          | LSP inlay hints                   | Lightest Accent (base1) `93a1a1`                                         | _Italic_ |
| `ui.fold_marker`         | Code fold indicators              | Lightest Accent (base1) `93a1a1`                                         | Normal   |
| `ui.indent_guide`        | Indent guide lines                | Light Background Contrast `eee8d5`                                       | —        |
| `ui.gutter`              | Sign / gutter column background   | Light Background Contrast `eee8d5`                                       | —        |
| `ui.popup.bg`            | Popup / float background          | Light Background Contrast `eee8d5`                                       | —        |
| `ui.popup.border`        | Popup / float border              | blue `268bd2`                                                            | —        |
| `ui.border`              | Inactive pane / split border      | Light Background Contrast `eee8d5`                                       | —        |
| `ui.border_active`       | Active pane / split border        | blue `268bd2`                                                            | —        |
| `ui.scrollbar`           | Scrollbar                         | fg: Lightest Accent (base1) `93a1a1`, bg: Light BG Contrast `eee8d5`     | —        |
| `ui.mark`                | Marked position / mark highlight  | bg: Violet `6c71c4`, fg: Light Background (base3) `fdf6e3`               | —        |
| `ui.pane_label`          | Pane / window identifier label    | Lightest Accent (base1) `93a1a1`                                         | Normal   |
| `ui.pane_label_active`   | Active pane / window label        | blue `268bd2`                                                            | Normal   |
| `ui.clock`               | Full-pane clock display           | blue `268bd2`                                                            | Normal   |

### Statusline

Applies to Neovim (mini.statusline, mini.tabline), Helix, tmux, yazi, and starship.

| Token Slug                 | Description                             | FG                               | BG                                 | Style    |
| -------------------------- | --------------------------------------- | -------------------------------- | ---------------------------------- | -------- |
| `status.bg`                | Default statusline background           | Dark Accent (base00) `657b83`    | Light BG Contrast (base2) `eee8d5` | —        |
| `status.filename`          | File name / buffer name                 | Dark Accent (base00) `657b83`    | —                                  | Normal   |
| `status.filename_modified` | Modified file indicator                 | yellow `b58900`                  | —                                  | **Bold** |
| `status.filename_readonly` | Read-only file indicator                | red `dc322f`                     | —                                  | **Bold** |
| `status.branch`            | Git branch name                         | green `859900`                   | —                                  | Normal   |
| `status.diff_added`        | Git diff added count                    | green `859900`                   | —                                  | **Bold** |
| `status.diff_deleted`      | Git diff deleted count                  | red `dc322f`                     | —                                  | **Bold** |
| `status.diag_error`        | Diagnostic error count badge            | red `dc322f`                     | —                                  | **Bold** |
| `status.diag_warning`      | Diagnostic warning count badge          | orange `cb4b16`                  | —                                  | Normal   |
| `status.diag_info`         | Diagnostic info count badge             | cyan `2aa198`                    | —                                  | Normal   |
| `status.position`          | Cursor position: line/col, percentage   | Dark Accent (base00) `657b83`    | —                                  | Normal   |
| `status.filetype`          | File type / language label              | Dark Accent (base00) `657b83`    | —                                  | Normal   |
| `status.mode_normal`       | Mode indicator — NORMAL                 | Light Background `fdf6e3`        | blue `268bd2`                      | **Bold** |
| `status.mode_insert`       | Mode indicator — INSERT                 | Light Background `fdf6e3`        | green `859900`                     | **Bold** |
| `status.mode_visual`       | Mode indicator — VISUAL / SELECT        | Light Background `fdf6e3`        | yellow `b58900`                    | **Bold** |
| `status.mode_replace`      | Mode indicator — REPLACE                | Light Background `fdf6e3`        | red `dc322f`                       | **Bold** |
| `status.mode_command`      | Mode indicator — COMMAND                | Light Background `fdf6e3`        | orange `cb4b16`                    | **Bold** |
| `status.session`           | tmux session name / multiplexer context | Light Background `fdf6e3`        | blue `268bd2`                      | **Bold** |
| `status.host`              | Hostname segment                        | Light Background `fdf6e3`        | green `859900`                     | Normal   |
| `status.time`              | Clock segment                           | Dark Accent (base00) `657b83`    | —                                  | Normal   |
| `status.date`              | Date segment                            | Lightest Accent (base1) `93a1a1` | —                                  | Normal   |
| `status.inactive`          | Inactive window / pane statusline       | Lightest Accent (base1) `93a1a1` | Light BG Contrast (base2) `eee8d5` | —        |
| `status.separator`         | Segment separators and dividers         | Lightest Accent (base1) `93a1a1` | —                                  | Normal   |
| `status.window`            | Window / tab list entry                 | Lightest Accent (base1) `93a1a1` | —                                  | Normal   |
| `status.window_current`    | Current window / tab                    | Dark Background `002b36`         | Light Background `fdf6e3`          | **Bold** |
| `status.window_activity`   | Window with unseen activity             | yellow `b58900`                  | —                                  | **Bold** |
| `status.window_bell`       | Window that rang the bell               | red `dc322f`                     | —                                  | **Bold** |
| `status.message`           | Status line message                     | Light Background `fdf6e3`        | yellow `b58900`                    | Normal   |
| `status.message_command`   | Command prompt                          | yellow `b58900`                  | Light Background `fdf6e3`          | Normal   |

### File Manager / Directory Listings

Applies to yazi, dircolors (`LS_COLORS`), and eza (`EZA_COLORS`).

| Token Slug            | Description                                   | Colour                            | Style    |
| --------------------- | --------------------------------------------- | --------------------------------- | -------- |
| `fs.dir`              | Directories                                   | blue `268bd2`                     | **Bold** |
| `fs.symlink`          | Symbolic links                                | cyan `2aa198`                     | **Bold** |
| `fs.executable`       | Executable files                              | red `dc322f`                      | **Bold** |
| `fs.source`           | Source code files                             | green `859900`                    | **Bold** |
| `fs.shell`            | Shell scripts                                 | orange `cb4b16`                   | Normal   |
| `fs.config`           | Configuration files                           | cyan `2aa198`                     | **Bold** |
| `fs.data`             | Data files: `.json`, `.yaml`, `.toml`, `.xml` | cyan `2aa198`                     | Normal   |
| `fs.document`         | Document files: `.md`, `.txt`, `.pdf`         | Light Accent (base0) `839496`     | Normal   |
| `fs.media`            | Images, audio, video                          | blue `268bd2`                     | Normal   |
| `fs.archive`          | Archives: `.zip`, `.tar`, `.gz`, …            | violet `6c71c4`                   | Normal   |
| `fs.notebook`         | Notebooks: `.ipynb`, `.livemd`, `.jlnb`       | yellow `b58900`                   | **Bold** |
| `fs.office`           | Office documents: `.docx`, `.xlsx`, `.pptx`   | magenta `d33682`                  | Normal   |
| `fs.orphan`           | Broken symlinks / missing targets             | red `dc322f` on Light BG `fdf6e3` | **Bold** |
| `fs.socket`           | Sockets and FIFOs                             | cyan `2aa198` on Dark BG `002b36` | Normal   |
| `fs.meta`             | Backup / temp files: `.bak`, `.swp`, `.orig`  | Lightest Accent (base1) `93a1a1`  | Normal   |
| `fs.permission_read`  | Read permission bit                           | yellow `b58900`                   | Normal   |
| `fs.permission_write` | Write permission bit                          | red `dc322f`                      | Normal   |
| `fs.permission_exec`  | Execute permission bit                        | green `859900`                    | Normal   |
| `fs.filesize`         | File size values                              | cyan `2aa198`                     | Normal   |

## Theming Strategy

Stylix manages desktop chrome only: GNOME shell, GTK, fonts, cursor, wallpaper.

Terminal and code-adjacent tools use manual Solarized themes so that shell
colours and editor syntax colours remain independent.

| Tool      | Config path                                         | Theme mechanism                                                                                                             |
| --------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Kitty     | `home/kitty.nix`                                    | Manual ANSI palette — complete, no changes needed                                                                           |
| Zsh       | `home/zsh.nix`                                      | `ZSH_HIGHLIGHT_STYLES` map — needs string/interpolation fix                                                                 |
| Helix     | `home/helix.nix`                                    | `nixotic_solarized_light.toml` — needs markup/data/UI gaps                                                                  |
| bat       | `home/bat.nix`                                      | `NixoticSolarizedLight` `.tmTheme` — needs markup/data gaps                                                                 |
| Neovim    | `files/neovim/init.lua`, `files/neovim/plugins.lua` | `vim-solarized8` + `nvim_set_hl` overrides (incl. mini.nvim) — needs gaps                                                   |
| VSCode    | `extensions/nixotic-solarized-light/`               | Standalone theme extension — install via symlink or VS Code command palette (`Developer: Install Extension from Location…`) |
| tmux      | `files/tmux/tmux.conf`                              | Native `set -g *-style` fragment read by Home Manager; Stylix tmux target disabled — complete                               |
| yazi      | `home/yazi.nix`                                     | `programs.yazi.theme` attrset — complete                                                                                    |
| dircolors | `files/dircolors/dir_colors`                        | Native 256-colour database read by Home Manager — needs palette audit                                                       |
| eza       | `home/eza.nix`                                      | `EZA_COLORS` env var — needs palette audit                                                                                  |
| starship  | `files/starship/starship.toml`                      | Custom `solarized-light` palette imported into Home Manager — complete                                                      |
| fzf       | `home/zsh.nix` (`programs.fzf`)                     | `FZF_DEFAULT_OPTS --color` — needs full build-out                                                                           |
| tig       | `files/git/tigrc`                                   | `color` directives — sparse, needs expansion                                                                                |
| btop      | `home/btop.nix`                                     | Theme file — needs build-out                                                                                                |
| atuin     | `home/atuin.nix`                                    | Inherits terminal ANSI palette — no action needed                                                                           |

---

## Appendix A — Neovim (`files/neovim/init.lua`)

Neovim uses two layers: legacy Vim highlight groups (for plugins and fallback)
and treesitter `@` capture groups (for parsed buffers). Both must be set. The
`role_hl` table in `files/neovim/init.lua` is the implementation target. mini.nvim
module setup lives in `files/neovim/plugins.lua`; package selection and loading
order remain in `home/neovim.nix`.

### A.1 Legacy Vim Groups

| Token Slug               | Vim Highlight Group(s)                                                   |
| ------------------------ | ------------------------------------------------------------------------ |
| `code.keyword`           | `Keyword`, `Conditional`, `Repeat`, `Statement`, `StorageClass`, `Label` |
| `code.variable`          | `Identifier`                                                             |
| `code.constant`          | `Constant`                                                               |
| `code.type`              | `Type`, `Structure`, `Typedef`                                           |
| `code.literal.string`    | `String`                                                                 |
| `code.literal.number`    | `Number`, `Float`                                                        |
| `code.literal.bool`      | `Boolean`                                                                |
| `code.literal.null`      | `Constant` (shared with variable constant — acceptable)                  |
| `code.function`          | `Function`                                                               |
| `code.import`            | `Include`, `PreProc`, `Define`                                           |
| `code.macro`             | `Macro`                                                                  |
| `code.interpolation`     | `Special`, `SpecialChar`                                                 |
| `code.comment`           | `Comment`                                                                |
| `code.doc_comment`       | `SpecialComment`                                                         |
| `code.operator`          | `Operator`                                                               |
| `code.punctuation`       | `Delimiter`                                                              |
| `markup.tag`             | `Tag`                                                                    |
| `markup.attribute`       | `htmlArg`, `xmlAttrib`                                                   |
| `markup.value`           | `htmlString`, `xmlString`                                                |
| `markup.entity`          | `htmlSpecialChar`, `xmlEntity`                                           |
| `markup.doctype`         | `htmlPreProc`, `xmlProcessing`                                           |
| `diff.added`             | `DiffAdd`                                                                |
| `diff.deleted`           | `DiffDelete`                                                             |
| `diff.changed`           | `DiffChange`                                                             |
| `diff.hunk`              | `DiffText`                                                               |
| `diag.error`             | `DiagnosticError`                                                        |
| `diag.warning`           | `DiagnosticWarn`                                                         |
| `diag.info`              | `DiagnosticInfo`                                                         |
| `diag.hint`              | `DiagnosticHint`                                                         |
| `ui.line_number`         | `LineNr`                                                                 |
| `ui.line_number_current` | `CursorLineNr`                                                           |
| `ui.cursor`              | `Cursor`, `CursorIM`                                                     |
| `ui.cursorline`          | `CursorLine`                                                             |
| `ui.selection`           | `Visual`                                                                 |
| `ui.match_bracket`       | `MatchParen`                                                             |
| `ui.search_current`      | `IncSearch`, `CurSearch`                                                 |
| `ui.search_other`        | `Search`                                                                 |
| `ui.inlay_hint`          | `LspInlayHint`                                                           |
| `ui.popup.bg`            | `NormalFloat`                                                            |
| `ui.popup.border`        | `FloatBorder`                                                            |

### A.2 Treesitter Capture Groups

| Token Slug            | Treesitter `@` Group(s)                                                            |
| --------------------- | ---------------------------------------------------------------------------------- |
| `code.keyword`        | `@keyword`, `@keyword.control`, `@keyword.storage`, `@keyword.return`              |
| `code.variable`       | `@variable`, `@variable.parameter`, `@variable.member`, `@variable.builtin`        |
| `code.constant`       | `@constant`, `@constant.builtin`                                                   |
| `code.type`           | `@type`, `@type.builtin`, `@constructor`                                           |
| `code.literal.string` | `@string`                                                                          |
| `code.literal.number` | `@number`, `@number.float`                                                         |
| `code.literal.bool`   | `@boolean`                                                                         |
| `code.function`       | `@function`, `@function.method`, `@function.builtin`, `@function.call`             |
| `code.import`         | `@keyword.import`, `@module`, `@module.builtin`                                    |
| `code.macro`          | `@keyword.directive`, `@keyword.directive.define`, `@attribute`, `@function.macro` |
| `code.interpolation`  | `@string.escape`, `@string.special`                                                |
| `code.regex`          | `@string.regexp`                                                                   |
| `code.comment`        | `@comment`                                                                         |
| `code.doc_comment`    | `@comment.documentation`                                                           |
| `code.operator`       | `@operator`                                                                        |
| `code.punctuation`    | `@punctuation`, `@punctuation.delimiter`, `@punctuation.bracket`                   |
| `markup.tag`          | `@tag`, `@tag.builtin`                                                             |
| `markup.attribute`    | `@tag.attribute`                                                                   |
| `markup.value`        | `@tag.attribute` (value sub-part — no distinct capture; inherit from attribute)    |
| `markup.entity`       | `@string.special.symbol` (XML/HTML entity context)                                 |
| `diff.added`          | `@diff.plus`                                                                       |
| `diff.deleted`        | `@diff.minus`                                                                      |
| `diff.changed`        | `@diff.delta`                                                                      |

### A.3 mini.nvim

mini.nvim modules are set up in `files/neovim/plugins.lua`; their highlight
groups are set in `role_hl` alongside the groups above. `role_hl` is reapplied
on every `ColorScheme` event so a colorscheme reload does not clear them.

| Token Slug                 | Highlight Group(s)                                                                             |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| `status.mode_normal`       | `MiniStatuslineModeNormal`, `MiniStatuslineModeOther`, `MiniTablineTabpagesection`             |
| `status.mode_insert`       | `MiniStatuslineModeInsert`                                                                     |
| `status.mode_visual`       | `MiniStatuslineModeVisual`                                                                     |
| `status.mode_replace`      | `MiniStatuslineModeReplace`                                                                    |
| `status.mode_command`      | `MiniStatuslineModeCommand`                                                                    |
| `status.bg`                | `MiniStatuslineDevinfo`, `MiniStatuslineFilename`, `MiniStatuslineFileinfo`, `MiniTablineFill` |
| `status.inactive`          | `MiniStatuslineInactive`                                                                       |
| `status.window`            | `MiniTablineVisible`, `MiniTablineHidden`                                                      |
| `status.window_current`    | `MiniTablineCurrent`                                                                           |
| `status.filename_modified` | `MiniTablineModifiedCurrent`, `MiniTablineModifiedVisible`, `MiniTablineModifiedHidden`        |
| `ui.selection`             | `MiniPickMatchCurrent`, `MiniPickPreviewLine`, `MiniFilesCursorLine`                           |
| `ui.mark`                  | `MiniPickMatchMarked`                                                                          |
| `diff.added`               | `MiniDiffSignAdd`                                                                              |
| `diff.changed`             | `MiniDiffSignChange`                                                                           |
| `diff.deleted`             | `MiniDiffSignDelete`                                                                           |

Mode foreground is always Light Background (`fdf6e3`). Modified tabline entries
keep the background of their state: Light Background (`fdf6e3`) when current,
Light BG Contrast (`eee8d5`) otherwise.

`MiniIcons*` colour groups map directly to the palette: Azure and Blue to blue
`268bd2`, Cyan to cyan `2aa198`, Green to green `859900`, Grey to Lightest
Accent (base1) `93a1a1`, Orange to orange `cb4b16`, Purple to violet `6c71c4`,
Red to red `dc322f`, Yellow to yellow `b58900`.

Picker and explorer selection rows use `ui.selection` and `ui.mark` rather than
`CursorLine` or `Visual`, because they sit on a `NormalFloat` background that
shares `eee8d5` with both.

Unlisted `Mini*` groups (`MiniFiles*`, `MiniPick*`, `MiniNotify*`,
`MiniSnippets*`, `MiniSurround`) keep mini's default links to float groups
(`NormalFloat`, `FloatBorder`, `FloatTitle`), `Directory`, `DiagnosticFloating*`,
`DiagnosticUnderline*` and `IncSearch`.

---

## Appendix B — Helix (`home/helix.nix`)

Helix theme inherits `solarized_light` and overrides specific keys. The theme
file is `xdg.configFile."helix/themes/nixotic_solarized_light.toml"`.

### B.1 Syntax Scopes

| Token Slug            | Helix Theme Key(s)                                                            |
| --------------------- | ----------------------------------------------------------------------------- |
| `code.keyword`        | `keyword`, `keyword.control`, `keyword.storage`                               |
| `code.variable`       | `variable`, `variable.parameter`, `variable.other.member`, `variable.builtin` |
| `code.constant`       | `constant`                                                                    |
| `code.type`           | `type`, `type.builtin`, `constructor`                                         |
| `code.literal.string` | `string`                                                                      |
| `code.literal.number` | `constant.numeric`                                                            |
| `code.literal.bool`   | `constant.builtin.boolean`                                                    |
| `code.function`       | `function`, `function.method`, `function.builtin`                             |
| `code.import`         | `keyword.control.import`, `namespace`                                         |
| `code.macro`          | `keyword.directive`, `attribute`                                              |
| `code.interpolation`  | `string.special`                                                              |
| `code.regex`          | `string.regexp`                                                               |
| `code.comment`        | `comment`                                                                     |
| `code.doc_comment`    | `comment.block.documentation`                                                 |
| `code.operator`       | `operator`                                                                    |
| `code.punctuation`    | `punctuation`, `punctuation.delimiter`, `punctuation.bracket`                 |
| `markup.tag`          | `tag`                                                                         |
| `markup.attribute`    | `attribute` (HTML context — shared with macro; acceptable)                    |
| `json.key`            | `variable` (JSON keys parsed as variable — correct by taxonomy)               |
| `diff.added`          | `diff.plus`                                                                   |
| `diff.deleted`        | `diff.minus`                                                                  |
| `diff.changed`        | `diff.delta`                                                                  |
| `diag.error`          | `diagnostic.error`                                                            |
| `diag.warning`        | `diagnostic.warning`                                                          |
| `diag.info`           | `diagnostic.info`                                                             |

### B.2 UI Keys

| Token Slug               | Helix Theme Key(s)              |
| ------------------------ | ------------------------------- |
| `ui.fg`                  | `ui.text`                       |
| `ui.bg`                  | `ui.background`                 |
| `ui.line_number`         | `ui.linenr`                     |
| `ui.line_number_current` | `ui.linenr.selected`            |
| `ui.cursor`              | `ui.cursor.normal`, `ui.cursor` |
| `ui.cursorline`          | `ui.cursorline.primary`         |
| `ui.selection`           | `ui.selection`                  |
| `ui.match_bracket`       | `ui.cursor.match`               |
| `ui.search_current`      | `ui.highlight.frameline`        |
| `ui.search_other`        | `ui.highlight`                  |
| `ui.inlay_hint`          | `ui.virtual.inlay-hint`         |
| `ui.popup.bg`            | `ui.popup`                      |
| `ui.popup.border`        | `ui.popup.border`               |
| `ui.indent_guide`        | `ui.virtual.indent-guide`       |
| `ui.gutter`              | `ui.gutter`                     |

### B.3 Statusline Keys

| Token Slug                 | Helix Theme Key(s)                          |
| -------------------------- | ------------------------------------------- |
| `status.bg`                | `ui.statusline`                             |
| `status.inactive`          | `ui.statusline.inactive`                    |
| `status.mode_normal`       | `ui.statusline.normal`                      |
| `status.mode_insert`       | `ui.statusline.insert`                      |
| `status.mode_visual`       | `ui.statusline.select`                      |
| `status.separator`         | `ui.statusline.separator`                   |
| `status.filename_modified` | `ui.text.modified` / `ui.bufferline.active` |

---

## Appendix C — VSCode (`extensions/nixotic-solarized-light/`)

The theme is delivered as a standalone VS Code extension at
`extensions/nixotic-solarized-light/`. Install it with a symlink or via the
command palette (`Developer: Install Extension from Location…`), then select
**Nixotic Solarized Light** in `Preferences: Color Theme`.

This appendix documents the TextMate scopes and workbench colour keys used in
the extension. The sections below are kept as reference; `home/vscode.nix` is
not modified.

### C.0 Extension install

```bash
ln -s "$PWD/extensions/nixotic-solarized-light" \
      "$HOME/.vscode/extensions/nixotic-solarized-light-0.1.0"
```

Reload VS Code after linking. Re-run the command if the extension version is
bumped in `package.json`.

### C.1 Token Colour Customizations (reference)

```jsonc
"editor.tokenColorCustomizations": {
  "textMateRules": [
    // code.comment
    { "scope": ["comment", "comment.block.documentation"],
      "settings": { "foreground": "#839496", "fontStyle": "italic" } },
    // code.keyword
    { "scope": ["keyword", "storage.type", "storage.modifier",
                "keyword.control", "keyword.operator.word"],
      "settings": { "foreground": "#859900", "fontStyle": "bold" } },
    // code.variable / code.constant
    { "scope": ["variable", "variable.other.readwrite",
                "variable.language", "constant", "support.constant"],
      "settings": { "foreground": "#268bd2" } },
    // code.type
    { "scope": ["entity.name.type", "support.type", "support.class",
                "entity.name.class", "entity.name.struct"],
      "settings": { "foreground": "#b58900" } },
    // code.literal.string
    { "scope": ["string"],
      "settings": { "foreground": "#2aa198" } },
    // code.literal.number + code.literal.bool
    { "scope": ["constant.numeric", "constant.language.boolean"],
      "settings": { "foreground": "#2aa198" } },
    // code.function
    { "scope": ["entity.name.function", "meta.function-call",
                "support.function", "variable.function"],
      "settings": { "foreground": "#cb4b16", "fontStyle": "italic" } },
    // code.import + code.macro
    { "scope": ["keyword.control.import", "keyword.control.from",
                "keyword.control.include", "entity.name.namespace",
                "meta.preprocessor", "entity.name.annotation",
                "storage.type.annotation"],
      "settings": { "foreground": "#d33682" } },
    // code.interpolation + code.regex
    { "scope": ["string.regexp", "constant.character.escape",
                "constant.other.placeholder", "meta.interpolation",
                "punctuation.definition.interpolation"],
      "settings": { "foreground": "#6c71c4" } },
    // code.operator + code.punctuation
    { "scope": ["punctuation", "keyword.operator"],
      "settings": { "foreground": "#839496" } },
    // markup.tag
    { "scope": ["entity.name.tag"],
      "settings": { "foreground": "#859900", "fontStyle": "bold" } },
    // markup.attribute
    { "scope": ["entity.other.attribute-name"],
      "settings": { "foreground": "#268bd2" } },
    // markup.doctype / css.at_rule
    { "scope": ["meta.preprocessor", "keyword.control.at-rule"],
      "settings": { "foreground": "#d33682" } },
    // css.selector
    { "scope": ["entity.name.tag.css", "entity.other.attribute-name.class",
                "entity.other.attribute-name.id"],
      "settings": { "foreground": "#b58900" } },
    // css.property
    { "scope": ["support.type.property-name"],
      "settings": { "foreground": "#268bd2" } },
    // diff.added / diff.deleted
    { "scope": ["markup.inserted"], "settings": { "foreground": "#859900" } },
    { "scope": ["markup.deleted"], "settings": { "foreground": "#dc322f" } },
    { "scope": ["markup.changed"], "settings": { "foreground": "#b58900" } }
  ]
}
```

### C.2 Workbench Colour Customizations (reference)

```jsonc
"workbench.colorCustomizations": {
  "editor.background":                   "#fdf6e3",
  "editor.foreground":                   "#839496",
  "editorLineNumber.foreground":         "#839496",
  "editorLineNumber.activeForeground":   "#657b83",
  "editor.selectionBackground":          "#eee8d5",
  "editor.lineHighlightBackground":      "#eee8d5",
  "editorCursor.foreground":             "#d33682",
  "editorCursor.background":             "#fdf6e3",
  "editor.findMatchBackground":          "#b58900",
  "editor.findMatchHighlightBackground": "#93a1a1",
  "editorBracketMatch.background":       "#eee8d5",
  "editorBracketMatch.border":           "#b58900",
  "editorInlayHint.foreground":          "#93a1a1",
  "editorInlayHint.background":          "#fdf6e3",
  "editorHoverWidget.background":        "#eee8d5",
  "editorHoverWidget.border":            "#268bd2",
  "editorSuggestWidget.background":      "#eee8d5",
  "editorSuggestWidget.border":          "#268bd2",
  "editorSuggestWidget.selectedBackground": "#fdf6e3",
  "statusBar.background":                "#eee8d5",
  "statusBar.foreground":                "#657b83",
  "statusBarItem.errorBackground":       "#dc322f",
  "statusBarItem.warningBackground":     "#cb4b16",
  "statusBar.debuggingBackground":       "#b58900",
  "editorError.foreground":              "#dc322f",
  "editorWarning.foreground":            "#cb4b16",
  "editorInfo.foreground":               "#2aa198"
}
```

---

## Appendix D — bat (`home/bat.nix`)

bat uses a Sublime Text `.tmTheme` XML (plist format) embedded inline. The
existing `NixoticSolarizedLight` theme is largely correct. Add the following
`<dict>` blocks to the `<array>` to cover gaps.

### D.1 Scopes to Add

```xml
<!-- markup.tag -->
<dict>
  <key>name</key><string>Markup Tag</string>
  <key>scope</key><string>entity.name.tag</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#859900</string>
    <key>fontStyle</key><string>bold</string>
  </dict>
</dict>
<!-- markup.attribute -->
<dict>
  <key>name</key><string>Markup Attribute</string>
  <key>scope</key><string>entity.other.attribute-name</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#268bd2</string>
  </dict>
</dict>
<!-- markup.entity -->
<dict>
  <key>name</key><string>Markup Entity</string>
  <key>scope</key><string>constant.character.entity</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#6c71c4</string>
  </dict>
</dict>
<!-- markup.doctype -->
<dict>
  <key>name</key><string>Markup Doctype</string>
  <key>scope</key><string>meta.tag.sgml.doctype</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#d33682</string>
  </dict>
</dict>
<!-- css.selector -->
<dict>
  <key>name</key><string>CSS Selector</string>
  <key>scope</key>
  <string>entity.name.tag.css, entity.other.attribute-name.class,
          entity.other.attribute-name.id, entity.other.attribute-name.pseudo-class</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#b58900</string>
  </dict>
</dict>
<!-- css.property -->
<dict>
  <key>name</key><string>CSS Property</string>
  <key>scope</key><string>support.type.property-name</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#268bd2</string>
  </dict>
</dict>
<!-- css.at_rule -->
<dict>
  <key>name</key><string>CSS At-Rule</string>
  <key>scope</key><string>keyword.control.at-rule</string>
  <key>settings</key><dict>
    <key>foreground</key><string>#d33682</string>
  </dict>
</dict>
<!-- diff.added / diff.deleted / diff.changed -->
<dict>
  <key>name</key><string>Diff Added</string>
  <key>scope</key><string>markup.inserted</string>
  <key>settings</key><dict><key>foreground</key><string>#859900</string></dict>
</dict>
<dict>
  <key>name</key><string>Diff Deleted</string>
  <key>scope</key><string>markup.deleted</string>
  <key>settings</key><dict><key>foreground</key><string>#dc322f</string></dict>
</dict>
<dict>
  <key>name</key><string>Diff Changed</string>
  <key>scope</key><string>markup.changed</string>
  <key>settings</key><dict><key>foreground</key><string>#b58900</string></dict>
</dict>
```

---

## Appendix E — Zsh (`home/zsh.nix`)

Full corrected `ZSH_HIGHLIGHT_STYLES` map. Changes from current config:

- `single-quoted-argument`, `double-quoted-argument`, `dollar-quoted-argument`,
  `back-quoted-argument` corrected from blue → cyan (`shell.string`)
- `dollar-quoted-argument` further set to violet (`shell.interpolation`) — it
  can contain escape sequences and is interpolation-like
- `command`, `builtin`, `function`, `alias` set to green/**bold**
  (`shell.command`)
- `commandseparator`, `redirection` set to base0 (`shell.separator`)

```nix
ZSH_HIGHLIGHT_STYLES[default]                  = 'fg=${solarized.lightAccent}';
ZSH_HIGHLIGHT_STYLES[unknown-token]            = 'fg=${solarized.red},bold';
ZSH_HIGHLIGHT_STYLES[commandunknown]           = 'fg=${solarized.red},bold';
ZSH_HIGHLIGHT_STYLES[comment]                  = 'fg=${solarized.lightAccent},italic';
ZSH_HIGHLIGHT_STYLES[reserved-word]            = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[alias]                    = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[suffix-alias]             = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[global-alias]             = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[precommand]               = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[command]                  = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[function]                 = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[builtin]                  = 'fg=${solarized.green},bold';
ZSH_HIGHLIGHT_STYLES[path]                     = 'fg=${solarized.blue}';
ZSH_HIGHLIGHT_STYLES[path_pathseparator]       = 'fg=${solarized.lightAccent}';
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]     = 'fg=${solarized.blue}';
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]     = 'fg=${solarized.blue}';
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]   = 'fg=${solarized.cyan}';
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]   = 'fg=${solarized.cyan}';
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]   = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]     = 'fg=${solarized.cyan}';
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument] = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]   = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[assign]                   = 'fg=${solarized.blue}';
ZSH_HIGHLIGHT_STYLES[globbing]                 = 'fg=${solarized.blue}';
ZSH_HIGHLIGHT_STYLES[history-expansion]        = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[commandseparator]         = 'fg=${solarized.lightAccent}';
ZSH_HIGHLIGHT_STYLES[redirection]              = 'fg=${solarized.lightAccent}';
ZSH_HIGHLIGHT_STYLES[named-fd]                 = 'fg=${solarized.lightAccent}';
ZSH_HIGHLIGHT_STYLES[process-substitution]     = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter] = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[arithmetic-expansion]     = 'fg=${solarized.violet}';
ZSH_HIGHLIGHT_STYLES[rc-quote]                 = 'fg=${solarized.cyan}';
```

---

## Appendix F — tmux (`files/tmux/tmux.conf`)

`files/tmux/tmux.conf` sets every colour option explicitly and annotates each
line with its token slug. `stylix.targets.tmux.enable = false` in
`home/stylix.nix` stops Stylix sourcing its base16 tmux file ahead of it.

> [!NOTE] Why Every Option Is Set
>
> tmux 3.8 added styled UI (tree-mode preview, menus, popups, copy-mode
> matches, scrollbars) whose defaults use tmux's built-in `theme*` colours.
> Any colour option left unset falls back to those defaults or, with the
> Stylix target enabled, to the base16 mapping. When tmux adds a new `*-style`
> or `*-colour` option, map it here and set it.

| Token Slug               | tmux Option(s)                                                           |
| ------------------------ | ------------------------------------------------------------------------ |
| `status.bg`              | `status-style`                                                           |
| `status.session`         | `status-left` (inline `#[…]`)                                            |
| `status.date`            | `status-right` (inline `#[…]`)                                           |
| `status.time`            | `status-right` (inline `#[…]`)                                           |
| `status.host`            | `status-right` (inline `#[…]`)                                           |
| `status.window`          | `window-status-style`                                                    |
| `status.window_current`  | `window-status-current-style`                                            |
| `status.window_activity` | `window-status-activity-style`                                           |
| `status.window_bell`     | `window-status-bell-style`                                               |
| `status.message`         | `message-style`                                                          |
| `status.message_command` | `message-command-style`                                                  |
| `status.separator`       | `tree-mode-border-style`                                                 |
| `ui.border`              | `pane-border-style`                                                      |
| `ui.border_active`       | `pane-active-border-style`                                               |
| `ui.scrollbar`           | `pane-scrollbars-style`                                                  |
| `ui.pane_label`          | `display-panes-colour`, `tree-mode-preview-style` (inactive branch)      |
| `ui.pane_label_active`   | `display-panes-active-colour`, `tree-mode-preview-style` (active branch) |
| `ui.popup.bg`            | `menu-style`, `popup-style`                                              |
| `ui.popup.border`        | `menu-border-style`, `popup-border-style`, `display-panes-border-style`  |
| `ui.selection`           | `mode-style`, `menu-selected-style`                                      |
| `ui.cursorline`          | `copy-mode-current-line-style`, `tree-mode-selection-style`              |
| `ui.search_current`      | `copy-mode-current-match-style`                                          |
| `ui.search_other`        | `copy-mode-match-style`, `switch-mode-match-style`                       |
| `ui.mark`                | `copy-mode-mark-style`                                                   |
| `ui.line_number`         | `copy-mode-line-number-style`                                            |
| `ui.line_number_current` | `copy-mode-current-line-number-style`                                    |
| `ui.clock`               | `clock-mode-colour`                                                      |

Window list colours live in the `window-status-*-style` options, not in
`#[…]` inside the `*-format` strings, so the activity and bell styles are not
masked by inline colours. `copy-mode-selection-style` and
`copy-mode-position-style` are left at their default, `#{E:mode-style}`.

> [!NOTE] Active Window Contrast
>
> `status.window_current` uses Dark Background (`#002b36`) as text on Light
> Background (`#fdf6e3`) for maximum contrast on the active window tab.

---

## Appendix G — fzf (`home/zsh.nix`)

fzf has no colour config currently. Add to `programs.fzf.defaultOptions` or set
`FZF_DEFAULT_OPTS` in `sessionVariables`.

```nix
programs.fzf = {
  enable = true;
  enableZshIntegration = false;
  defaultOptions = [
    # Solarized Light — matches status.bg / ui.* slugs
    "--color=bg+:#eee8d5"        # ui.selection background
    "--color=bg:#fdf6e3"         # ui.bg
    "--color=border:#268bd2"     # ui.popup.border
    "--color=fg:#839496"         # ui.fg
    "--color=fg+:#657b83"        # ui.line_number_current (selected item)
    "--color=gutter:#fdf6e3"     # ui.gutter
    "--color=header:#d33682"     # code.import / heading
    "--color=hl:#b58900"         # ui.search_current (match highlight)
    "--color=hl+:#b58900"        # ui.search_current (selected match)
    "--color=info:#839496"       # status info text
    "--color=marker:#859900"     # multi-select marker → green
    "--color=pointer:#268bd2"    # cursor pointer → blue
    "--color=prompt:#268bd2"     # prompt → blue
    "--color=query:#657b83"      # typed query text
    "--color=scrollbar:#93a1a1"  # scrollbar → lightest accent
    "--color=separator:#93a1a1"  # separator line
    "--color=spinner:#2aa198"    # loading spinner → cyan
  ];
};
```

---

## Appendix H — dircolors (`files/dircolors/dir_colors`)

The current config uses 256-colour ANSI codes. The table below maps each
category to the correct named palette colour and its nearest 256-colour index.
Update the native database to use these consistently; `home/dircolors.nix` reads
it into `extraConfig`.

| Token Slug      | Colour Name             | Hex      | 256-colour index | Current code  | Correct code    |
| --------------- | ----------------------- | -------- | ---------------- | ------------- | --------------- |
| `fs.dir`        | blue                    | `268bd2` | 33               | `01;34`       | `01;38;5;33`    |
| `fs.symlink`    | cyan                    | `2aa198` | 37               | `01;36`       | `01;38;5;37`    |
| `fs.executable` | red                     | `dc322f` | 160              | `01;38;5;160` | `01;38;5;160` ✓ |
| `fs.source`     | green                   | `859900` | 64               | `01;38;5;64`  | `01;38;5;64` ✓  |
| `fs.shell`      | orange                  | `cb4b16` | 166              | `00;38;5;166` | `00;38;5;166` ✓ |
| `fs.config`     | cyan                    | `2aa198` | 37               | `01;38;5;37`  | `01;38;5;37` ✓  |
| `fs.data`       | cyan                    | `2aa198` | 37               | `01;38;5;37`  | `01;38;5;37` ✓  |
| `fs.document`   | Light Accent (base0)    | `839496` | 245              | `00;38;5;245` | `00;38;5;245` ✓ |
| `fs.media`      | blue                    | `268bd2` | 33               | `00;38;5;33`  | `00;38;5;33` ✓  |
| `fs.archive`    | violet                  | `6c71c4` | 61               | `01;38;5;61`  | `01;38;5;61` ✓  |
| `fs.notebook`   | yellow                  | `b58900` | 136              | `01;38;5;136` | `01;38;5;136` ✓ |
| `fs.office`     | magenta                 | `d33682` | 125              | `01;38;5;125` | `01;38;5;125` ✓ |
| `fs.meta`       | Lightest Accent (base1) | `93a1a1` | 245 (approx)     | `00;38;5;240` | `00;38;5;245`   |

Changes required: `DIR` from `01;34` → `01;38;5;33`; `LINK` from `01;36` →
`01;38;5;37`; `fs.meta` from index 240 → 245.

---

## Appendix I — eza (`home/eza.nix`)

`EZA_COLORS` uses ANSI 256-colour codes. Map to palette:

```nix
EZA_COLORS = [
  # Permissions
  "ur=38;5;64"   # read   → green (fs.permission_read via yellow is conventional; green used here)
  "uw=38;5;160"  # write  → red
  "ux=38;5;64"   # exec   → green
  "ue=38;5;160"  # exec (special) → red
  "gr=38;5;64"   # group read  → green
  "gw=38;5;160"  # group write → red
  "gx=38;5;64"   # group exec  → green
  "tr=38;5;64"   # other read  → green
  "tw=38;5;160"  # other write → red
  "tx=38;5;64"   # other exec  → green
  # Size
  "sn=38;5;37"   # file size number → cyan
  "sb=38;5;136"  # file size unit   → yellow
  # Special
  "xx=38;5;33"   # punctuation / separators → blue
].join(":");
```

> [!NOTE] EZA Colours
>
> `EZA_COLORS` is a colon-separated string in the Nix `sessionVariables`
> attrset; the list above must be joined. The current string is mostly correct;
> `sn` (size number) should be cyan (`37`) not green (`32`), and `sb` (size
> unit) should be yellow (`136`) not orange/yellow (`33`).

---

## Appendix J — tig (`files/git/tigrc`)

tig has a limited colour model. Expand `tigrc` with the following:

```text
# ── Solarized Light — docs/theme.md ──
color cursor          color15   color5     bold   # base3 fg on magenta bg
color title-focus     color15   color4     bold   # base3 on blue — active title (status.mode_normal)
color title-blur      color10   color7            # base1 on base2 — inactive title (status.inactive)
color main-tag        color160  default    bold   # red — tags
color main-local-tag  color160  default    bold   # red — local tags
color main-remote     color166  default           # orange — remote refs
color main-tracked    color33   default           # blue — tracked branch
color main-head       color64   default    bold   # green — HEAD
color diff-header     color245  default    bold   # base0/bold — file headers (diff.file_header)
color diff-chunk      color37   default           # cyan — hunk headers (diff.hunk)
color diff-add        color64   default           # green — added (diff.added)
color diff-del        color160  default           # red — deleted (diff.deleted)
color diff-index      color245  default           # base0
color diff-oldmode    color245  default
color diff-newmode    color245  default
color "^commit "      color33   default    bold   # blue — commit hash
color "^Author: "     color33   default           # blue
color "^Date: "       color245  default           # base0
```

---

## Appendix K — btop (`home/btop.nix`)

btop ships named themes. The closest available theme is `solarized_light`. Set
it in `programs.btop.settings`:

```nix
programs.btop = {
  enable = true;
  settings = {
    color_theme = "solarized_light";
    theme_background = true;
  };
};
```

If `solarized_light` is not available in the btop package, the fallback is
`default` and the terminal ANSI palette (Kitty) provides approximate colours. A
custom btop theme matching the full palette can be written to
`~/.config/btop/themes/nixotic_solarized_light.theme` if needed — flag this to
implement as a follow-up.

---

## Appendix L — Known Gaps and Follow-ups

| Item                                   | Status         | Notes                                                                                                                                                                                                                                  |
| -------------------------------------- | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| delta                                  | Not configured | Diffs currently paged via bat. Add `[delta]` to `home/git.nix` if delta is installed. Slug mappings: `diff.*` and `ui.*` apply directly.                                                                                               |
| lazygit                                | Not present    | Not in config. No action needed.                                                                                                                                                                                                       |
| btop custom theme                      | Deferred       | Use `solarized_light` built-in for now. Custom theme file if needed.                                                                                                                                                                   |
| VSCode Stylix                          | Disabled       | `stylix.targets.vscode.enable = false` intentional — Settings Sync manages it cross-platform. Install the standalone extension from `extensions/nixotic-solarized-light/`; Appendix C documents the TextMate scopes used in the theme. |
| `solarized-base64` palette in starship | Dead code      | The `solarized-base64` palette in `home/starship.nix` is unused. Safe to remove.                                                                                                                                                       |
