```ansi
 ███╗  ██╗██╗██╗  ██╗ ██████╗ ████████╗██╗ ██████╗
 ████╗ ██║██║╚██╗██╔╝██╔═══██╗╚══██╔══╝██║██╔════╝
 ██╔██╗██║██║ ╚███╔╝ ██║   ██║   ██║   ██║██║
 ██║╚████║██║ ██╔██╗ ██║   ██║   ██║   ██║██║
 ██║ ╚═██║██║██╔╝ ██╗╚██████╔╝   ██║   ██║╚██████╗
 ╚═╝   ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝ ╚═════╝

        ❄  Flakes + Home Manager + Disko  ❄
```

## Hosts

| Host        | Role                                      |
| ----------- | ----------------------------------------- |
| `ambul8r`   | Workstation — laptop, NVIDIA GPU, GNOME   |
| `illumin8r` | Server — WSL dev container host, CLI only |
| `cre8r`     | Server — provisioning helper VM, CLI only |

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

See [docs/install.md](../docs/install.md) for the full walkthrough.

## Ongoing Updates

```bash
nh os switch
```

See [docs/validation.md](../docs/validation.md) for the validation pipeline
to run before applying changes.

## License

[MIT](LICENSE)
