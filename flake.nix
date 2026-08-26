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

      # Each function's Nim source file is named without a hyphen (e.g.
      # GetAttribute.nim) because Nim's `import` requires a valid identifier,
      # but the installed binary keeps the hyphenated PascalCase Verb-Noun
      # name (e.g. Get-Attribute) that aliases and PATH lookups expect. That
      # mapping is spelled out explicitly per function below rather than
      # derived from the filename, because a generic source-name ->
      # binary-name transform isn't safe in general (e.g. "ConvertTo-H264Video"
      # has two capitalized words before the hyphen, so a mechanical "insert
      # hyphen before capitals" reversal would misplace it). Add one entry
      # here per future migration — the build guard in packages.${system}.nim-functions
      # below fails loudly if a functions/*.nim file is ever added without a
      # matching entry.
      nimFunctionBinaries = {
        "Get-Attribute" = "GetAttribute.nim";
        "Get-Attributes" = "GetAttributes.nim";
        "Set-Attribute" = "SetAttribute.nim";
        "Remove-Attribute" = "RemoveAttribute.nim";
      };

      # role selects the whole experience: "workstation" = Stylix +
      # home/desktop.nix, "server" = no Stylix + home/headless.nix.
      # homeConfig overrides the home profile only (e.g. WSL).
      mkHost = { hostPath, role ? "workstation", homeConfig ? null }:
        let
          isWorkstation = role == "workstation";
          home =
            if homeConfig != null then homeConfig
            else if isWorkstation then ./home/desktop.nix
            else ./home/headless.nix;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            hostPath
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupCommand = "backup-$(date +%Y%m%d%H%M%S)";
              home-manager.extraSpecialArgs = { inherit self; };
              home-manager.users.axl = import home;
            }
          ] ++ nixpkgs.lib.optionals isWorkstation [
            stylix.nixosModules.stylix
            ./stylix.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        # prepare:hosts — Prepare-NewHost inserts scaffolded hosts below this line.
        ambul8r = mkHost { hostPath = ./hosts/ambul8r/configuration.nix; };

        illumin8r = mkHost {
          hostPath   = ./hosts/illumin8r/configuration.nix;
          role       = "server";
          homeConfig = ./home/wsl.nix;
        };

        cre8r = mkHost {
          hostPath = ./hosts/cre8r/configuration.nix;
          role     = "server";
        };
      };

      apps.${system} = {
        prepare = {
          type = "app";
          program = toString (pkgs.writeShellScript "nixotic-prepare" ''
            set -euo pipefail
            rm -rf /tmp/nixotic-prepare
            cp -r ${self} /tmp/nixotic-prepare
            chmod -R u+w /tmp/nixotic-prepare
            chmod +x /tmp/nixotic-prepare/files/zsh/functions/Prepare-NewHost
            exec /tmp/nixotic-prepare/files/zsh/functions/Prepare-NewHost "$@"
          '');
        };
      };

      packages.${system}.nim-functions = pkgs.stdenv.mkDerivation {
        pname = "nixotic-nim-functions";
        version = "0.1.0";
        src = ./files/nim;
        nativeBuildInputs = [ pkgs.nim ];
        buildPhase = ''
          runHook preBuild
          mkdir -p $out/bin

          wired="${pkgs.lib.concatStringsSep " " (builtins.attrValues nimFunctionBinaries)}"
          for f in functions/*.nim; do
            base="$(basename "$f")"
            case " $wired " in
              *" $base "*) ;;
              *)
                echo "error: functions/$base has no entry in nimFunctionBinaries (flake.nix)" >&2
                exit 1
                ;;
            esac
          done

          ${pkgs.lib.concatStringsSep "\n" (pkgs.lib.mapAttrsToList
            (binName: srcFile:
              ''nim c -d:release --nimcache:.nimcache -o:"$out/bin/${binName}" functions/${srcFile}'')
            nimFunctionBinaries)}

          runHook postBuild
        '';
        dontInstall = true;
      };

      checks.${system}.nim-functions-tests = pkgs.stdenv.mkDerivation {
        pname = "nixotic-nim-functions-tests";
        version = "0.1.0";
        src = ./files/nim;
        nativeBuildInputs = [ pkgs.nim pkgs.attr ];
        buildPhase = ''
          runHook preBuild
          for f in lib/tests/*.nim functions/tests/*.nim; do
            nim c -r --nimcache:.nimcache -o:"$TMPDIR/$(basename "$f" .nim)" "$f"
          done
          runHook postBuild
        '';
        installPhase = ''
          mkdir -p $out
          touch $out/tests-passed
        '';
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "nixotic-nim";
        packages = [ pkgs.nim pkgs.attr ];
      };
    };
}
