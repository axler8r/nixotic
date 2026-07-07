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

| Host        | Role                              |
| ----------- | --------------------------------- |
| `ambul8r`   | Laptop, NVIDIA GPU, GNOME desktop |
| `illumin8r` | WSL dev container host, CLI only  |
| `infer8r`   | ML workstation (planned)          |

## Stack

- **NixOS** with Flakes
- **Home Manager** (as a NixOS module)
- **GNOME** desktop
- **Stylix** (Solarized Light theme)
- **ZSH** shell

## Installation

New hosts are provisioned over SSH from an existing machine (normally the
`cre8r` helper VM) using nixos-anywhere — one command, unattended. The new
machine boots the stock NixOS ISO and waits; nothing is typed on it beyond
setting a root password.

See [docs/install.md](../docs/install.md) for the full walkthrough.

## Ongoing Updates

```bash
nh os switch
```

See [docs/validation.md](../docs/validation.md) for the validation pipeline
to run before applying changes.

## License

[MIT](LICENSE)
