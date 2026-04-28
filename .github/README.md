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


## Installation
To bring up a new host, use the automated installer — it partitions the disk,
sets up ZFS, and runs `nixos-install` in one step:

```bash
sudo nix run github:axler8r/nixotic#install -- ambul8r
```

See [docs/install.md](../docs/install.md) for the full install and first-boot
workflow, including how to persist the hardware configuration after reboot.


## Ongoing Updates
```bash
nh os switch
```

See [docs/validation.md](../docs/validation.md) for the validation pipeline
to run before applying changes.


## License
[MIT](LICENSE)
