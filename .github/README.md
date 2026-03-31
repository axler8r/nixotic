# Nixotic

Quixotic NixOS Flakes + Home Manager configuration.

## Hosts

| Host      | Role                              |
| --------- | --------------------------------- |
| `ambul8r` | Laptop, NVIDIA GPU, GNOME desktop |
| `infer8r` | ML workstation (planned)          |

## Stack

- **NixOS** with Flakes
- **Home Manager** (as a NixOS module)
- **GNOME** desktop
- **Stylix** (Solarized Light theme)
- **ZSH** shell

## First-Time Setup

```bash
git clone https://github.com/axler8r/nixotic.git ~/.nixotic
cd ~/.nixotic
sudo nixos-rebuild switch --flake .#<host>
```

After the first build, use `nh os switch` for subsequent updates.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

[MIT](LICENSE)
