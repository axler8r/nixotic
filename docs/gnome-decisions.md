# GNOME Configuration Decisions

Design decisions for the GNOME desktop configuration.

**Updated:** February 2026

## Theming

Stylix manages desktop chrome only: GNOME shell, GTK, fonts, cursor, and wallpaper.
Terminal and code-adjacent tools use manual Solarized themes, keeping shell colours
and editor syntax colours independent of the base16 palette.

| Tool   | Theme source                            |
| ------ | --------------------------------------- |
| GNOME  | Stylix (Solarized Light base16 scheme)  |
| GTK    | Stylix                                  |
| Kitty  | Manual ANSI palette in `home/kitty.nix` |
| Helix  | Custom `nixotic_solarized_light`        |
| bat    | Custom `NixoticSolarizedLight`          |
| Neovim | vim-solarized8 (manual, not Stylix)     |

Syntax colour preferences are documented in [theme.md](theme.md).

## Philosophy

**Less is better.** Start minimal and add only what's needed. The goal is a
clean, distraction-free environment focused on:

- VS Code (primary IDE)
- Neovim (secondary editor)
- Kitty + tmux (terminal)
- Brave (browser)
- Obsidian (knowledge management)

## Dock Favorites

| App              | Rationale                            |
| ---------------- | ------------------------------------ |
| Files (Nautilus) | Need a file manager                  |
| Brave            | Main browser - fast, privacy-focused |
| Obsidian         | Knowledge management                 |
| VS Code          | Primary IDE                          |
| Kitty            | Primary terminal                     |

## Excluded GNOME Apps

Removed via `environment.gnome.excludePackages` in host configuration:

| App            | Reason             |
| -------------- | ------------------ |
| cheese         | Have phone camera  |
| epiphany       | Have Brave/Firefox |
| geary          | Use web email      |
| gnome-contacts | Use phone          |
| gnome-tour     | Not needed         |
| snapshot       | Have phone camera  |
| xterm          | Have Kitty         |
| yelp           | Not needed         |

## Installed Apps

Installed via `home.packages` in [home/gnome.nix](../home/gnome.nix):

| Category  | Apps                                           |
| --------- | ---------------------------------------------- |
| Browsers  | Firefox, Chromium (ungoogled)                  |
| Editors   | Apostrophe (Markdown)                          |
| Media     | Celluloid (video), Shortwave (radio), Podcasts |
| System    | Mission Center, GParted, dconf-editor          |
| Utilities | File Roller, GNOME Tweaks, Power Manager       |
| Knowledge | Obsidian                                       |

## Extensions

| Extension           | Rationale                                     |
| ------------------- | --------------------------------------------- |
| Clipboard Indicator | Essential for programmers - clipboard history |
| Caffeine            | Prevent sleep during builds/presentations     |
| Dash to Dock        | Bottom dock with auto-hide                    |
| Date Menu Formatter | ISO8601 date format (yyyy-MM-dd HH:mm)        |
| Just Perfection     | UI customization                              |
| Tiling Assistant    | Window management productivity                |
| Vitals              | CPU, memory, temp in panel                    |

## App Folders

Organized into 6 folders:

| Folder       | Contents                                          |
| ------------ | ------------------------------------------------- |
| Internet     | Brave, Chromium, Firefox                          |
| Command Line | Helix, htop, nvim, ranger                         |
| Utilities    | Seahorse, Tweaks, Settings                        |
| Handy        | Calculator, Calendar, Characters, Papers, etc.    |
| Media        | Celluloid, Loupe, mpv, Music, Podcasts, Shortwave |
| System       | btop, dconf-editor, GParted, Mission Center, etc. |

## Hidden Apps

| App                    | Reason                                    |
| ---------------------- | ----------------------------------------- |
| Manage Printing (CUPS) | Ugly icon; can access via `localhost:631` |

## Keyboard Customizations

| Setting             | Value         | Rationale                    |
| ------------------- | ------------- | ---------------------------- |
| Compose key         | Right Alt     | Type special characters      |
| Caps Lock           | Ctrl modifier | Ergonomic Ctrl access        |
| IBus Unicode hotkey | Ctrl+Alt+U    | Frees Ctrl+Shift+U for Kitty |
| Window buttons      | Left side     | macOS-style close/min/max    |

## Screen Lock

| Setting     | Value                            |
| ----------- | -------------------------------- |
| Blank after | 10 minutes                       |
| Lock after  | 5 min after blank (15 min total) |
