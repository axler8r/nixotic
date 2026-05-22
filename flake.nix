{
  description = "Nixotic, the Quixotic NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, disko, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHost = { hostPath, enableStylix ? true, homeConfig ? ./home/desktop.nix }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            hostPath
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupCommand = "backup-$(date +%Y%m%d%H%M%S)";
              home-manager.users.axl = import homeConfig;
            }
          ] ++ nixpkgs.lib.optionals enableStylix [
            stylix.nixosModules.stylix
            ./stylix.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        ambul8r = mkHost { hostPath = ./hosts/ambul8r/configuration.nix; };

        illumin8r = mkHost {
          hostPath     = ./hosts/illumin8r/configuration.nix;
          enableStylix = false;
          homeConfig   = ./home/wsl.nix;
        };

        # ML workstation (TODO: configure when ready)
        # infer8r = mkHost { hostPath = ./hosts/infer8r/configuration.nix; };
      };

      apps.${system} = {
        install = {
          type = "app";
          program = toString (pkgs.writeShellScript "nixotic-install" ''
            set -euo pipefail
            export NIXOTIC_DISKO=${disko}
            rm -rf /tmp/nixotic
            cp -r ${self} /tmp/nixotic
            chmod -R u+w /tmp/nixotic
            chmod +x /tmp/nixotic/scripts/Install-NixOS.sh
            exec /tmp/nixotic/scripts/Install-NixOS.sh "$@"
          '');
        };

        prepare = {
          type = "app";
          program = toString (pkgs.writeShellScript "nixotic-prepare" ''
            set -euo pipefail
            rm -rf /tmp/nixotic-prepare
            cp -r ${self} /tmp/nixotic-prepare
            chmod -R u+w /tmp/nixotic-prepare
            chmod +x /tmp/nixotic-prepare/scripts/Prepare-NewHost.sh
            exec /tmp/nixotic-prepare/scripts/Prepare-NewHost.sh "$@"
          '');
        };
      };
    };
}
