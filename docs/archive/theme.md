# Colour Preferences


## Introduction
My preferred colours for coding and terminal work.

> [!NOTE]
> The goal is consistency: the same kind of token should look the same
> wherever practical.


## Rules
1. Stylix manages desktop chrome only: GNOME shell, GTK, fonts, cursor, and wallpaper.
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


## My Syntax Highlighting Preferences
| Syntactic Element                            | Colour               | Style    | Hex      |
| -------------------------------------------- | -------------------- | -------- | -------- |
| Keywords (`if`, `for`, `return`, `def`, ...) | green                | **Bold** | `859900` |
| Variables, constants                         | blue                 | Normal   | `268bd2` |
| Classes, objects, types                      | yellow               | Normal   | `b58900` |
| Strings, booleans, integers, floats          | cyan                 | Normal   | `2aa198` |
| Macros, pragmas, imports/includes/uses       | magenta              | Normal   | `d33682` |
| Functions, procedures, methods               | orange               | _Italic_ | `cb4b16` |
| Regex, string interpolations                 | violet               | Normal   | `6c71c4` |
| Comments                                     | Light Accent (base0) | _Italic_ | `839496` |
| Punctuation, operators, default foreground   | Light Accent (base0) | Normal   | `839496` |

> [!NOTE]
> - Strings and numeric/boolean literals intentionally share cyan.
> - Comments, punctuation, operators, and default foreground intentionally share base0.
> - Imports/includes/uses and macros/pragmas intentionally share magenta.


## Zsh Preferences
For interactive `zsh` command-line highlighting, use semantic colours that make
command construction easy to scan while staying close to the overall palette.

| Shell Element                       | Colour               | Style    | Hex      |
| ----------------------------------- | -------------------- | -------- | -------- |
| Valid commands, builtins, functions | green                | Normal   | `859900` |
| Invalid or unknown commands         | red                  | **Bold** | `dc322f` |
| Options and arguments               | blue                 | Normal   | `268bd2` |
| Shell keywords / reserved words     | green                | **Bold** | `859900` |
| Comments                            | Light Accent (base0) | _Italic_ | `839496` |
| Separators and default foreground   | Light Accent (base0) | Normal   | `839496` |

> [!NOTE]
>
> - Command validity should be visually obvious while typing.
> - Option names such as `--color` and general arguments should both read as blue.
> - Shell-specific readability takes priority over mirroring editor token categories exactly.


## Diagnostics
Editor diagnostic colours are configured per-editor.

| Severity | Colour | Hex      |
| -------- | ------ | -------- |
| Error    | red    | `dc322f` |
| Warning  | orange | `cb4b16` |
| Info     | cyan   | `2aa198` |

Neovim and Helix may require explicit overrides if built-in themes do not match
these diagnostic preferences.


## Theming Strategy
Stylix manages desktop chrome only: GNOME shell, GTK, fonts, cursor, wallpaper.

Terminal and code-adjacent tools use manual Solarized themes so that shell colours
and editor syntax colours remain independent:

| Tool    | Theme source                                                     |
| ------- | ---------------------------------------------------------------- |
| Kitty   | Manual ANSI palette in `home/kitty.nix`                          |
| Zsh     | Manual shell highlighting in `home/zsh.nix` plus `dircolors`     |
| Nushell | Manual `solarized_light` config in `files/nushell/config.nu`     |
| Helix   | Custom `nixotic_solarized_light` in `home/helix.nix`             |
| bat     | Custom `NixoticSolarizedLight` in `home/bat.nix`                 |
| Neovim  | `vim-solarized8` plus manual role overrides in `home/neovim.nix` |
