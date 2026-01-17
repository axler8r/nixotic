# GNOME Configuration Decisions

Design decisions made when configuring GNOME for this NixOS setup.

**Date:** January 2026  
**Context:** Migration from Ubuntu to NixOS for a programmer/architect workstation

## Philosophy

**Less is better.** Start minimal and add only what's needed. The goal is a
*clean, distraction-free environment focused on:
- VS Code (primary IDE)
- Neovim (secondary editor)
- Kitty + tmux (terminal)
- Brave (browser)
- Obsidian (knowledge management) — *pending fix*

## Dock Favorites

| App              | Rationale                            |
| ---------------- | ------------------------------------ |
| Files (Nautilus) | Need a file manager                  |
| Brave            | Main browser — fast, privacy-focused |
| VS Code          | Primary IDE                          |
| Kitty            | Primary terminal                     |

**Removed from dock:**
- Slack, Signal → use web/phone versions
- Chromium → one browser is enough
- Cider → niche, proprietary

## Excluded GNOME Apps

All removed because alternatives exist or they're unused:

| Category  | Removed                                                     | Reason                                          |
| --------- | ----------------------------------------------------------- | ----------------------------------------------- |
| Terminals | gnome-terminal, xterm                                       | Have Kitty                                      |
| Browsers  | epiphany                                                    | Have Brave                                      |
| Email     | geary                                                       | Use web email                                   |
| Media     | totem, gnome-music, gnome-photos, cheese, snapshot          | Have mpv for video; don't need photo management |
| PIM       | gnome-calendar, gnome-clocks, gnome-weather, gnome-contacts | Use phone/web                                   |
| Utilities | baobab, gnome-connections, simple-scan, gnome-logs          | Rarely needed                                   |
| Help      | yelp, gnome-tour                                            | Not needed                                      |
| Monitors  | gnome-system-monitor                                        | htop is enough                                  |

## Kept GNOME Apps

| App         | Rationale                                       |
| ----------- | ----------------------------------------------- |
| Calculator  | Quick math without terminal                     |
| Evince      | PDF viewer — essential                          |
| File Roller | Archive extraction — will need this             |
| Loupe       | Quick image preview — lighter than alternatives |
| Seahorse    | GPG key management — sign commits               |
| Settings    | Core GNOME functionality                        |
| Tweaks      | GNOME customization                             |

## Extensions

| Extension           | Rationale                                     |
| ------------------- | --------------------------------------------- |
| Clipboard Indicator | Essential for programmers — clipboard history |
| Caffeine            | Prevent sleep during builds/presentations     |
| Tiling Assistant    | Window management productivity                |

**Not included:**
- Vitals → htop is enough for system monitoring
- DING (desktop icons) → desktop clutter
- Date formatters, timers → minor tweaks, not worth the complexity

## App Folders

Simplified to 3 folders (down from 7):

| Folder             | Contents                  | Rationale                   |
| ------------------ | ------------------------- | --------------------------- |
| Command Line Tools | helix, htop, nvim, ranger | Group CLI apps together     |
| Utilities          | Calculator, Evince, etc.  | Infrequently used GUI tools |
| Media              | mpv                       | Single media app            |

## Hidden Apps

| App                    | Reason                                    |
| ---------------------- | ----------------------------------------- |
| Manage Printing (CUPS) | Ugly icon; can access via `localhost:631` |

## Future Considerations

- **Obsidian**: Currently broken (Electron/Wayland issue). Revisit later.
- **nvtop**: Add when configuring `infer8r` (ML workstation with GPU)
- **NVIDIA Settings**: Add for `infer8r`
- **Styling**: Color scheme, themes, fonts — deferred to future session
