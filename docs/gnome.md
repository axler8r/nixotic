# GNOME Configuration

How GNOME desktop is configured in this NixOS setup.

## Architecture

| Concern                     | Location                    | Mechanism                              |
| --------------------------- | --------------------------- | -------------------------------------- |
| Enable GNOME desktop        | `hosts/*/configuration.nix` | `services.desktopManager.gnome.enable` |
| Exclude default apps        | `hosts/*/configuration.nix` | `environment.gnome.excludePackages`    |
| Exclude xterm               | `hosts/*/configuration.nix` | `services.xserver.excludePackages`     |
| Add system-wide GNOME tools | `hosts/*/configuration.nix` | `environment.systemPackages`           |
| Dock favorites              | `home/gnome.nix`            | `dconf.settings`                       |
| App folders                 | `home/gnome.nix`            | `dconf.settings`                       |
| Extensions                  | `home/gnome.nix`            | `home.packages` + `dconf.settings`     |
| Hide desktop entries        | `home/gnome.nix`            | `xdg.desktopEntries.<name>.noDisplay`  |

## Key Files

- [home/gnome.nix](../home/gnome.nix) — User-level GNOME configuration (dconf, extensions, folders)
- `hosts/*/configuration.nix` — System-level GNOME setup

## Discovering dconf Keys

Watch for changes in real-time:
```bash
dconf watch /
```

Then change a setting in GNOME Settings or an app — the key path and value will appear.

Dump a specific schema:
```bash
dconf dump /org/gnome/shell/
```

## Finding Desktop File Names

Desktop entries must use exact filenames. Find them with:
```bash
ls /run/current-system/sw/share/applications/ | grep -i <appname>
ls /etc/profiles/per-user/axl/share/applications/ | grep -i <appname>
```

Note: Names are case-sensitive (e.g., `Helix.desktop` not `helix.desktop`).

## Extensions

Extensions are installed via `home.packages` and enabled via dconf:

```nix
# Install
home.packages = with pkgs; [
  gnomeExtensions.clipboard-indicator
  gnomeExtensions.caffeine
];

# Enable
dconf.settings."org/gnome/shell" = {
  disable-user-extensions = false;
  enabled-extensions = [
    "clipboard-indicator@tudmotu.com"
    "caffeine@patapon.info"
  ];
};
```

Extension UUIDs can be found with `gnome-extensions list` or on
[extensions.gnome.org](https://extensions.gnome.org).

## Troubleshooting

**Settings don't apply after rebuild:**
Log out and back in. Some dconf changes require a session restart.

**App not appearing in folder:**
Check the exact `.desktop` filename (see "Finding Desktop File Names" above).

**Extension not loading:**
Verify GNOME version compatibility. Check `journalctl -f` while logging in.

## References

- [NixOS Wiki: GNOME](https://wiki.nixos.org/wiki/GNOME)
- [Hoverbear: Declarative GNOME Configuration](https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/)
- [Home Manager dconf options](https://nix-community.github.io/home-manager/options.xhtml#opt-dconf.settings)
