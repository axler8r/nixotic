```ansi
                        ███╗  ██╗██╗██╗  ██╗ ██████╗ ████████╗██╗ ██████╗
                        ████╗ ██║██║╚██╗██╔╝██╔═══██╗╚══██╔══╝██║██╔════╝
                        ██╔██╗██║██║ ╚███╔╝ ██║   ██║   ██║   ██║██║
                        ██║╚████║██║ ██╔██╗ ██║   ██║   ██║   ██║██║
                        ██║ ╚═██║██║██╔╝ ██╗╚██████╔╝   ██║   ██║╚██████╗
                        ╚═╝   ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝ ╚═════╝

                                The Quixotic NixOS Configuration

                          ❄  Flakes + Home Manager + Stylix + Disko  ❄
```

## Stack

- **NixOS** with Flakes
- **Home Manager** (as a NixOS module)
- **GNOME** desktop
- **Stylix** (Solarized Light theme)
- **ZSH** shell

## Installation

New hosts are provisioned over SSH from a Nixotic Source using nixos-anywhere —
one command, unattended. The new machine boots the stock NixOS ISO and waits;
nothing is typed on it beyond setting a root password.

See [docs/install.md](docs/install.md) for the full walkthrough.

## Ongoing Updates

```bash
nh os switch
```

See [docs/validation.md](docs/validation.md) for the validation pipeline
to run before applying changes.

## Configuration Sources

Home Manager owns packages, integration, and deployment. Structured settings
remain in `home/`; substantial native configuration lives in `files/` and is
referenced or imported by the corresponding module.

See [docs/packages.md](docs/packages.md#configuration-ownership) for ownership
rules and [docs/validation.md](docs/validation.md#native-configuration-checks)
for the focused native configuration check.

## License

[MIT](LICENSE)
