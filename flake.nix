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

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;
      nimDir = ./ax;

      # Build logic lives under nix/; this file only wires the outputs.
      nim = import ./nix/nim.nix { inherit pkgs lib nimDir; };
      ax = import ./nix/ax.nix {
        inherit
          pkgs
          lib
          nimDir
          nim
          ;
      };
      mkHost = import ./nix/mkhost.nix { inherit inputs self system; };
      formatter = import ./nix/formatter.nix { inherit pkgs; };
    in
    {
      nixosConfigurations = {
        # prepare:hosts — Prepare-NewHost inserts scaffolded hosts below this line.
        ambul8r = mkHost { hostPath = ./hosts/ambul8r/configuration.nix; };

        illumin8r = mkHost {
          hostPath = ./hosts/illumin8r/configuration.nix;
          role = "server";
          homeConfig = ./home/wsl.nix;
        };

        cre8r = mkHost {
          hostPath = ./hosts/cre8r/configuration.nix;
          role = "server";
        };
      };

      apps.${system} = {
        prepare = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "nixotic-prepare" ''
              set -euo pipefail
              rm -rf /tmp/nixotic-prepare
              cp -r ${self} /tmp/nixotic-prepare
              chmod -R u+w /tmp/nixotic-prepare
              chmod +x /tmp/nixotic-prepare/files/zsh/functions/Prepare-NewHost
              exec /tmp/nixotic-prepare/files/zsh/functions/Prepare-NewHost "$@"
            ''
          );
        };
      };

      packages.${system}.ax = ax.axPackage;

      formatter.${system} = formatter;

      checks.${system} = import ./nix/checks.nix {
        inherit
          pkgs
          lib
          nimDir
          nim
          ax
          formatter
          ;
        src = self;
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "nixotic-nim";
        packages = nim.nimToolchain ++ [
          pkgs.gnumake
          # Editor tooling: Helix finds the Nim language server and
          # formatter on the PATH direnv provides.
          pkgs.nimlangserver
          pkgs.nph
        ];
      };
    };
}
