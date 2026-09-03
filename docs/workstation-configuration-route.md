# Workstation Configuration Route
This document shows what future Nixotic workstation hosts look like when they
are scaffolded through `Prepare-NewHost` and evaluated through `flake.nix`.

It describes the reusable workstation shape rather than the existing `ambul8r`
laptop. The key difference is that future workstations use the shared
ZFS-on-root disk wrapper by default, while `ambul8r` keeps its legacy ext4
plus `dpool` layout until a future reinstall.

The diagrams show configuration composition and ownership boundaries. They do
not show imperative execution order; NixOS and Home Manager modules are merged
by their respective module systems.

Unless stated otherwise, diagrams in this document describe the scaffolded
future-state route, not the current `ambul8r` host file.


## Scaffold Route
A future workstation normally starts with `Prepare-NewHost`.

```bash
Prepare-NewHost <hostname> --role workstation --profile fixed
```

For a portable workstation, usually a laptop:

```bash
Prepare-NewHost <hostname> --role workstation --profile portable
```

Because `workstation` is the default role, omitting `--role workstation` has the
same result.

```mermaid
flowchart TD
    Command["Prepare-NewHost &lt;hostname&gt;\n--role workstation\n--profile fixed|portable"]
    Guards["Preflight guards\nclean stable branch, nix, curl,\nGitHub reachable, host does not exist"]
    HostDir["hosts &lt;hostname&gt;"]
    Config["configuration.nix"]
    Disk["disk.nix"]
    Hardware["hardware-configuration.nix\nplaceholder"]
    FlakeEdit["flake.nix entry inserted\nafter # prepare:hosts"]
    Check["nix flake check --no-build"]
    Branch["wip/YYYYMMDD-XXXXXXX\ncommit scaffold"]

    Command --> Guards
    Guards --> HostDir
    HostDir --> Config
    HostDir --> Disk
    HostDir --> Hardware
    HostDir --> FlakeEdit
    FlakeEdit --> Check
    Check --> Branch
```

The generated flake entry for a workstation is intentionally thin:

```nix
<hostname> = mkHost { hostPath = ./hosts/<hostname>/configuration.nix; };
```

No explicit `role` is needed because `mkHost` defaults to
`role = "workstation"`.


## Flake Route
`flake.nix` turns the generated host entry into a full NixOS configuration.

```mermaid
flowchart TD
    Flake["flake.nix"]
    HostEntry["nixosConfigurations.<hostname>"]
    MkHost["mkHost\nrole default: workstation\nhomeConfig default: null"]
    IsWorkstation["isWorkstation = true"]
    HomeProfile["home profile\nhome/desktop.nix"]
    NixosSystem["nixpkgs.lib.nixosSystem"]

    HostPath["hostPath\nhosts/<hostname>/configuration.nix"]
    DiskoModule["disko.nixosModules.disko"]
    HMModule["home-manager.nixosModules.home-manager"]
    HMUser["home-manager.users.axl\nimport home/desktop.nix"]
    StylixModule["stylix.nixosModules.stylix"]
    StylixConfig["stylix.nix"]

    Flake --> HostEntry
    HostEntry --> MkHost
    MkHost --> HostPath
    MkHost --> IsWorkstation
    IsWorkstation --> HomeProfile
    MkHost --> NixosSystem

    HostPath --> NixosSystem
    DiskoModule --> NixosSystem
    HMModule --> NixosSystem
    HMUser --> NixosSystem
    StylixModule --> NixosSystem
    StylixConfig --> NixosSystem
```

For every future workstation, `mkHost` adds:

- the host's own `configuration.nix`
- Disko support
- Home Manager as a NixOS module
- `home/desktop.nix` for user `axl`
- Stylix's NixOS module
- the root `stylix.nix` theme configuration


## Generated Host Module
For a workstation, `Prepare-NewHost` generates this import shape:

```nix
{
  imports = [
    ./hardware-configuration.nix
    ./disk.nix
    ../common/zfs-root.nix
    ../common/workstation.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "<hostname>";
  networking.hostId = "<random-8-hex-chars>";

  system.stateVersion = "25.11";
}
```

Current-state note: `ambul8r` is a legacy workstation and does not currently
import `../common/zfs-root.nix`; it keeps its existing ZFS/runtime settings in
`hosts/ambul8r/configuration.nix`.

That file is deliberately small. It owns only the host identity and the first
boot defaults. Hardware quirks are added there later only when the running
machine proves it needs them.

```mermaid
flowchart TD
    HostConfig["hosts/<hostname>/configuration.nix"]
    Hardware["hardware-configuration.nix\nplaceholder, replaced during install"]
    DiskWrapper["disk.nix\nfixed or portable wrapper"]
    ZfsRoot["hosts/common/zfs-root.nix\nZFS runtime settings"]
    Workstation["hosts/common/workstation.nix\nGNOME workstation role"]
    Base["hosts/common/base.nix\nshared host baseline"]

    Identity["Host identity\nhostName, hostId"]
    Boot["Boot defaults\nsystemd-boot, EFI"]
    State["system.stateVersion"]

    HostConfig --> Hardware
    HostConfig --> DiskWrapper
    HostConfig --> ZfsRoot
    HostConfig --> Workstation
    Workstation --> Base

    HostConfig --> Identity
    HostConfig --> Boot
    HostConfig --> State
```


## Disk Route
Future workstations use the shared ZFS-on-root Disko layout in
`hosts/common/zfs-root-disk.nix`.

For a fixed workstation, `disk.nix` is generated as:

```nix
import ../common/zfs-root-disk.nix {
  device = "/dev/nvme0n1";
  swap   = "zram";
}
```

For a portable workstation, `disk.nix` is generated as:

```nix
import ../common/zfs-root-disk.nix {
  device      = "/dev/nvme0n1";
  swap        = "hibernate";
  swapSizeGiB = 64;
}
```

Before install, the `device` must be checked against the target machine with
`lsblk`. For portable hosts, `swapSizeGiB` should be set to at least the
machine's RAM.

```mermaid
flowchart TD
    DiskNix["hosts/<hostname>/disk.nix"]
    SharedLayout["hosts/common/zfs-root-disk.nix"]
    Profile{"profile"}
    Fixed["fixed\nzram swap\nno hibernation"]
    Portable["portable\nswap partition\nresumeDevice"]

    ESP["ESP\n1G vfat\n/boot"]
    Swap["optional swap partition\nportable only"]
    Rpool["rpool\nZFS pool"]
    Root["ROOT/nixos\n/"]
    Nix["HOSTDATA/nix\n/nix"]
    Docker["HOSTDATA/var/lib/docker\n/var/lib/docker"]
    UserData["USERDATA/home/axl/*\nDocuments, Downloads, Media,\nProjects, Vaults"]

    DiskNix --> SharedLayout
    DiskNix --> Profile
    Profile --> Fixed
    Profile --> Portable
    SharedLayout --> ESP
    SharedLayout --> Swap
    SharedLayout --> Rpool
    Rpool --> Root
    Rpool --> Nix
    Rpool --> Docker
    Rpool --> UserData
```


## Workstation System Role
The shared workstation role is `hosts/common/workstation.nix`. It imports the
shared base role and then adds desktop system behavior.

```mermaid
flowchart TD
    Workstation["hosts/common/workstation.nix"]
    Base["hosts/common/base.nix"]

    Network["NetworkManager"]
    Desktop["GNOME\nGDM, X server, keyboard"]
    Audio["PipeWire\nALSA + Pulse compatibility"]
    Docker["Docker\nZFS storage driver"]
    Security["ClamAV\nOpenSSH"]
    UserGroups["axl groups\nnetworkmanager, docker"]
    Packages["system and user packages\nBrave, admin tools, fonts"]

    Locale["timezone and locale"]
    User["user axl\nzsh, wheel, SSH key"]
    Nix["Nix settings\nflakes, caches, GC"]
    Shell["system zsh\nnix-ld"]

    Workstation --> Base
    Workstation --> Network
    Workstation --> Desktop
    Workstation --> Audio
    Workstation --> Docker
    Workstation --> Security
    Workstation --> UserGroups
    Workstation --> Packages

    Base --> Locale
    Base --> User
    Base --> Nix
    Base --> Shell
```

This role is the reusable system-level template for workstations. Host-specific
hardware should not be added here unless it applies to all future workstations.


## Home Manager Route
All workstation hosts use the same Home Manager profile as `ambul8r`:
`home/desktop.nix`.

```mermaid
flowchart TD
    HM["home-manager.users.axl"]
    Desktop["home/desktop.nix"]
    HomeBase["home/base.nix"]

    DesktopImports["desktop imports\natuin, bat, btop, claude, eza,\nfastfetch, fd, gh, gnome, gpg,\nhtop, jq, kitty, neovim, nh,\nnushell, ripgrep, stylix, vscode, yazi"]
    BaseImports["base imports\ndircolors, direnv, files, git,\nhelix, starship, tmux, zsh"]
    DesktopPackages["desktop packages\ncodex, claude-code, dev tools,\nCLI tools, media tools"]
    GnomeUser["home/gnome.nix\nGNOME apps, dconf,\nXDG dirs, extensions"]
    Files["files/\ndotfiles, zsh functions,\ncompletions, app configs"]
    Editor["EDITOR = nvim"]

    HM --> Desktop
    Desktop --> HomeBase
    Desktop --> DesktopImports
    Desktop --> DesktopPackages
    Desktop --> GnomeUser
    Desktop --> Editor
    HomeBase --> BaseImports
    BaseImports --> Files
```

This is what makes future workstations share the same user environment as
`ambul8r`. To keep that true, future workstation entries in `flake.nix` should
not set a custom `homeConfig`.


## Stylix Route
Future workstations also get the same Stylix route as `ambul8r`.

```mermaid
flowchart TD
    WorkstationRole["role = workstation"]
    RootStylix["stylix.nix\nNixOS-level theme"]
    HomeStylix["home/stylix.nix\nHome Manager target overrides"]

    Scheme["Solarized Light\nbase16 scheme"]
    Wallpaper["Wallpaper00.jpg"]
    Fonts["Inter, Cascadia Code,\nDejaVu Serif, Noto Emoji"]
    Cursor["Bibata cursor"]
    DisabledSystemTargets["system target exceptions\nchromium, kmscon"]
    DisabledHomeTargets["home target exceptions\nstarship, qt, vscode,\nkitty, helix, bat, yazi, btop"]
    Icons["Papirus-Light\nGTK icon theme"]

    WorkstationRole --> RootStylix
    WorkstationRole --> HomeStylix
    RootStylix --> Scheme
    RootStylix --> Wallpaper
    RootStylix --> Fonts
    RootStylix --> Cursor
    RootStylix --> DisabledSystemTargets
    HomeStylix --> DisabledHomeTargets
    HomeStylix --> Icons
```


## Full Future Workstation Graph
This is the complete reusable workstation route in one diagram.

```mermaid
flowchart LR
    Prepare["Prepare-NewHost\n--role workstation"]
    Flake["flake.nix\nmkHost default workstation"]
    Host["hosts/<hostname>/configuration.nix\nthin host wrapper"]
    Disk["hosts/<hostname>/disk.nix\nZFS-on-root wrapper"]
    ZfsDisk["hosts/common/zfs-root-disk.nix\npartition and dataset layout"]
    ZfsRuntime["hosts/common/zfs-root.nix\nruntime ZFS settings"]
    Workstation["hosts/common/workstation.nix\nshared workstation system"]
    Base["hosts/common/base.nix\nshared host baseline"]
    Home["home/desktop.nix\nshared user profile"]
    Files["files/\nlinked user assets and scripts"]
    Theme["stylix.nix + home/stylix.nix\nshared theme route"]
    System["Future workstation\nNixOS + Home Manager"]

    Prepare --> Flake
    Flake --> Host
    Host --> Disk
    Disk --> ZfsDisk
    Host --> ZfsRuntime
    Host --> Workstation
    Workstation --> Base
    Flake --> Home
    Home --> Files
    Flake --> Theme

    ZfsDisk --> System
    ZfsRuntime --> System
    Workstation --> System
    Base --> System
    Home --> System
    Theme --> System
```


## What Future Workstations Share
Future workstation hosts share:

- the same `mkHost` workstation path in `flake.nix`
- the same system baseline from `hosts/common/base.nix`
- the same workstation system role from `hosts/common/workstation.nix`
- the same ZFS-on-root layout from `hosts/common/zfs-root-disk.nix`
- the same ZFS runtime settings from `hosts/common/zfs-root.nix`
- the same Home Manager profile from `home/desktop.nix`
- the same user dotfile source tree under `files/`
- the same Stylix theme path

They should differ only where the physical machine requires it:

- disk device name
- fixed versus portable swap profile
- generated hardware configuration
- GPU driver and bus IDs
- hibernation, suspend, or firmware quirks
- host-specific services or peripherals


## Where Changes Belong
| Change type | Usual location |
| --- | --- |
| Make every future workstation behave differently at the system level | `hosts/common/workstation.nix` |
| Make every host behave differently, workstation or server | `hosts/common/base.nix` |
| Change the default future workstation disk layout | `hosts/common/zfs-root-disk.nix` |
| Change runtime ZFS behavior for new ZFS-on-root hosts | `hosts/common/zfs-root.nix` |
| Change all workstation user tools or dotfiles | `home/desktop.nix`, imported `home/*.nix`, or `files/` |
| Change GNOME user preferences or desktop apps | `home/gnome.nix` |
| Change shared workstation theming | `stylix.nix` or `home/stylix.nix` |
| Add one machine's hardware-specific settings | `hosts/<hostname>/configuration.nix` |
| Change how hosts are composed | `flake.nix` |

The rule of thumb is simple: shared workstation policy goes in the shared
workstation modules; machine facts and quirks stay in the generated host
directory.
