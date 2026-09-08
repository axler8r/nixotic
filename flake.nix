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
      lib = pkgs.lib;
      nimDir = ./files/nim;

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
        "Get-Verb" = "GetVerb.nim";
        "Show-Verb" = "ShowVerb.nim";
        "Sync-FileIndex" = "SyncFileIndex.nim";
        "Initialize-ClaudeProject" = "InitializeClaudeProject.nim";
        "Get-Help" = "GetHelp.nim";
        "Update-DockerImage" = "UpdateDockerImage.nim";
        "Remove-DockerDanglingImages" = "RemoveDockerDanglingImages.nim";
        "Remove-DockerDanglingVolumes" = "RemoveDockerDanglingVolumes.nim";
        "Get-DefaultBrowser" = "GetDefaultBrowser.nim";
        "Update-DevEnvironment" = "UpdateDevEnvironment.nim";
        "Write-Executable" = "WriteExecutable.nim";
        "Enter-NixShell" = "EnterNixShell.nim";
        "ConvertTo-VideoHorizontal" = "ConvertToVideoHorizontal.nim";
        "Invoke-GitRepositoryOptimization" = "InvokeGitRepositoryOptimization.nim";
        "Update-GitRepository" = "UpdateGitRepository.nim";
        "Get-ZfsSnapshots" = "GetZfsSnapshots.nim";
        "New-ToolDevEnvironment" = "NewToolDevEnvironment.nim";
        "New-PythonDevEnvironment" = "NewPythonDevEnvironment.nim";
        "New-DotNetDevEnvironment" = "NewDotNetDevEnvironment.nim";
        "New-ElixirDevEnvironment" = "NewElixirDevEnvironment.nim";
        "Remove-DevEnvironment" = "RemoveDevEnvironment.nim";
        "New-GitWIPBranch" = "NewGitWipBranch.nim";
        "Complete-GitWIPBranch" = "CompleteGitWipBranch.nim";
        "Remove-GitWIPBranch" = "RemoveGitWipBranch.nim";
        "Update-GitStableBranch" = "UpdateGitStableBranch.nim";
        "New-GitTag" = "NewGitTag.nim";
        "Get-GitHubLicenses" = "GetGitHubLicenses.nim";
        "Get-DockerImages" = "GetDockerImages.nim";
        "Get-DanglingDockerImages" = "GetDanglingDockerImages.nim";
        "Get-DockerDanglingVolumes" = "GetDockerDanglingVolumes.nim";
        "Find-DockerImages" = "FindDockerImages.nim";
        "Get-SwapUsage" = "GetSwapUsage.nim";
        "Resolve-GitRepositoryPath" = "ResolveGitRepositoryPath.nim";
        "Get-NfsExports" = "GetNfsExports.nim";
        "Find-MixedIndentation" = "FindMixedIndentation.nim";
        "Measure-Words" = "MeasureWords.nim";
        "Show-FileSizeHistogram" = "ShowFileSizeHistogram.nim";
      };

      # Fails at eval time (before any build runs) if functions/*.nim and
      # nimFunctionBinaries ever drift apart in either direction: a file added
      # without an entry, or an entry left behind after its file was deleted.
      checkedNimFunctionBinaries =
        let
          onDisk = builtins.attrNames
            (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nim" name)
              (builtins.readDir (nimDir + "/functions")));
          mapped = builtins.attrValues nimFunctionBinaries;
          unmapped = lib.subtractLists mapped onDisk;
          stale = lib.subtractLists onDisk mapped;
        in
        if unmapped != [ ] then
          throw "flake.nix: functions/*.nim on disk with no nimFunctionBinaries entry: ${toString unmapped}"
        else if stale != [ ] then
          throw "flake.nix: nimFunctionBinaries entries with no matching functions/*.nim file: ${toString stale}"
        else nimFunctionBinaries;

      # nim.cfg + lib/*.nim + lexicon.json shared by every function.
      # lib/tests is excluded so editing a lib test doesn't invalidate every
      # function's build cache. lexicon.json rides along because
      # lib/lexicon.nim embeds it with staticRead.
      nimShared = lib.fileset.difference
        (lib.fileset.unions
          [ (nimDir + "/nim.cfg") (nimDir + "/lib") (nimDir + "/lexicon.json") ])
        (nimDir + "/lib/tests");

      # One derivation per function, sourced from only nim.cfg + lib/ + its own
      # functions/<srcFile> -- so editing one function (or an unrelated test)
      # only invalidates that function's own build, not every other one's.
      mkNimFunction = binName: srcFile:
        pkgs.stdenv.mkDerivation {
          pname = "nixotic-nim-fn-${binName}";
          version = "0.1.0";
          src = lib.fileset.toSource {
            root = nimDir;
            fileset = lib.fileset.union nimShared (nimDir + "/functions/${srcFile}");
          };
          nativeBuildInputs = [ pkgs.nim ];
          buildPhase = ''
            runHook preBuild
            mkdir -p $out/bin
            nim c -d:release --nimcache:.nimcache -o:"$out/bin/${binName}" functions/${srcFile}
            runHook postBuild
          '';
          dontInstall = true;
        };

      # Toolchain plus every runtime dependency the tests exercise for real
      # (not just past a checkDeps guard). Shared with the devShell so a local
      # `nim c -r` run and the sandboxed check see the same set.
      nimToolchain = [
        pkgs.nim
        pkgs.attr
        pkgs.git
        pkgs.xdg-utils
        pkgs.parallel
        pkgs.ffmpeg
        pkgs.nix
        pkgs.direnv
        pkgs.util-linux
      ];

      # One derivation per test file, mirroring mkNimFunction's granularity:
      # a test only rebuilds when its own fileset changes, and Nix runs the
      # suites in parallel rather than serially in a single buildPhase.
      #
      # Deliberately built WITHOUT -d:release, unlike mkNimFunction above:
      # live `assert`/`doAssert` checks and readable stack traces are worth
      # more in a test binary than the speed release mode buys. Do not "fix"
      # this to match the package build.
      mkNimTest = { name, testPath, extraFiles ? [ ] }:
        pkgs.stdenv.mkDerivation {
          pname = "nixotic-nim-test-${name}";
          version = "0.1.0";
          src = lib.fileset.toSource {
            root = nimDir;
            fileset = lib.fileset.unions ([ nimShared (nimDir + "/${testPath}") ] ++ extraFiles);
          };
          nativeBuildInputs = nimToolchain;
          buildPhase = ''
            runHook preBuild
            nim c -r --nimcache:"$TMPDIR/nimcache" -o:"$TMPDIR/${name}" ${testPath}
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            touch $out/${name}-passed
            runHook postInstall
          '';
        };

      nimTestFiles = subdir:
        builtins.attrNames
          (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nim" name)
            (builtins.readDir (nimDir + "/${subdir}")));

      # Every functions/tests/*.nim imports exactly the one function module it
      # exercises. Reading that import back out is what lets a function test be
      # scoped as narrowly as the function's own build, instead of pinning the
      # whole functions/ directory. Fails at eval time if the convention breaks.
      nimTestSubject = testFile:
        let
          lines = lib.splitString "\n"
            (builtins.readFile (nimDir + "/functions/tests/${testFile}"));
          hits = lib.filter (m: m != null)
            (map (l: builtins.match "[[:space:]]*import[[:space:]]+\"\\.\\./([A-Za-z0-9]+)\".*" l) lines);
        in
        if hits == [ ] then
          throw "flake.nix: functions/tests/${testFile} has no `import \"../<Module>\"` line to scope its build against"
        else builtins.head (builtins.head hits);

      nimTests =
        (map
          (f: mkNimTest {
            name = lib.removeSuffix ".nim" f;
            testPath = "lib/tests/${f}";
          })
          (nimTestFiles "lib/tests"))
        ++
        (map
          (f: mkNimTest {
            name = lib.removeSuffix ".nim" f;
            testPath = "functions/tests/${f}";
            extraFiles = [ (nimDir + "/functions/${nimTestSubject f}.nim") ];
          })
          (nimTestFiles "functions/tests"));

      # ------------------------------------------------------------------ ax
      # The ax command tree: commands/<group>/[<subgroup>/]<leaf>.nim maps
      # mechanically to binary ax-<group>[-<subgroup>]-<leaf>. Lowercase
      # path segments make the mapping reversible, so no hand-maintained
      # name table is needed; the eval-time checks below replace the old
      # drift guard.
      axVersion = "0.1.0";
      axCommandsDir = nimDir + "/commands";

      relCommands = src:
        lib.removePrefix (toString axCommandsDir + "/") (toString src);

      commandSources =
        let all = lib.filesystem.listFilesRecursive axCommandsDir;
        in lib.filter
          (p: lib.hasSuffix ".nim" (toString p)
              && !(lib.hasInfix "/tests/" (toString p)))
          all;

      commandPath = src:
        lib.splitString "/" (lib.removeSuffix ".nim" (relCommands src));
      binName = src: "ax-" + lib.concatStringsSep "-" (commandPath src);

      axLexicon = builtins.fromJSON (builtins.readFile (nimDir + "/lexicon.json"));
      axAllowedLeaves =
        (map (v: v.name) axLexicon.verbs) ++ axLexicon.reportNouns;
      axGroups = builtins.fromJSON
        (builtins.readFile (axCommandsDir + "/groups.json"));

      # Fails at eval time (before any build runs) on: a source outside the
      # 2-3 word grammar, a path segment the mechanical mapping cannot
      # reverse, a leaf outside the lexicon, or a group directory missing
      # its groups.json summary.
      checkedCommandSources =
        let
          problems = lib.concatMap
            (src:
              let
                path = commandPath src;
                leaf = lib.last path;
                badSegs = lib.filter
                  (s: builtins.match "[a-z][a-z0-9]*" s == null) path;
                prefixes = [ (lib.take 1 path) ]
                  ++ lib.optional (lib.length path == 3) (lib.take 2 path);
                missingGroups = lib.filter
                  (p: !(axGroups ? ${lib.concatStringsSep " " p})) prefixes;
              in
              lib.optional (lib.length path < 2 || lib.length path > 3)
                "${relCommands src}: command depth must be 2 or 3 words"
              ++ map (s: "${relCommands src}: segment '${s}' must match [a-z][a-z0-9]*") badSegs
              ++ lib.optional (!(lib.elem leaf axAllowedLeaves))
                "${relCommands src}: leaf '${leaf}' is not a lexicon verb or report-noun"
              ++ map
                (p: "${relCommands src}: group '${lib.concatStringsSep " " p}' has no groups.json entry")
                missingGroups)
            commandSources;
        in
        if problems != [ ] then
          throw "flake.nix: ${lib.concatStringsSep "; " problems}"
        else commandSources;

      # One derivation per command, mirroring mkNimFunction's granularity:
      # nimShared plus the command's own source, nothing else.
      mkAxCommand = src:
        pkgs.stdenv.mkDerivation {
          pname = "ax-cmd-${binName src}";
          version = axVersion;
          src = lib.fileset.toSource {
            root = nimDir;
            fileset = lib.fileset.union nimShared src;
          };
          nativeBuildInputs = [ pkgs.nim ];
          buildPhase = ''
            runHook preBuild
            mkdir -p $out/libexec/ax
            nim c -d:release --nimcache:.nimcache \
              -o:"$out/libexec/ax/${binName src}" "commands/${relCommands src}"
            runHook postBuild
          '';
          dontInstall = true;
        };

      axDriver = pkgs.stdenv.mkDerivation {
        pname = "ax-driver";
        version = axVersion;
        src = lib.fileset.toSource {
          root = nimDir;
          fileset = lib.fileset.union nimShared (nimDir + "/ax.nim");
        };
        nativeBuildInputs = [ pkgs.nim ];
        buildPhase = ''
          runHook preBuild
          mkdir -p $out/bin
          nim c -d:release -d:axVersion=${axVersion} --nimcache:.nimcache \
            -o:$out/bin/ax ax.nim
          runHook postBuild
        '';
        dontInstall = true;
      };

      # A runCommand, NOT a symlinkJoin, and the driver is a real copy:
      # getAppFilename() reads /proc/self/exe, which fully resolves
      # symlinks, and the driver finds libexec/ax and share/ax relative to
      # itself. Command binaries stay symlinked (they locate nothing
      # relative to themselves), so a one-command edit rebuilds one small
      # derivation plus this trivial join. The registry is DERIVED here
      # from the binaries actually built -- it cannot disagree with them.
      axPackage = pkgs.runCommand "ax" { } ''
        install -Dm755 ${axDriver}/bin/ax $out/bin/ax
        mkdir -p $out/libexec/ax $out/share/ax $out/share/zsh/site-functions
        ${lib.concatMapStringsSep "\n"
          (src: "ln -s ${mkAxCommand src}/libexec/ax/${binName src} $out/libexec/ax/${binName src}")
          checkedCommandSources}
        "$out/bin/ax" self build-registry > $out/share/ax/registry.json
        cp ${nimDir}/commands/groups.json $out/share/ax/groups.json
        "$out/bin/ax" self completion zsh > $out/share/zsh/site-functions/_ax
      '';

      # A command test's subject is derived from the test's own path
      # (commands/<dir>/tests/test_<leaf>.nim -> commands/<dir>/<leaf>.nim)
      # -- mechanical rather than content-parsed, unlike the retired
      # nimTestSubject import scraping.
      axTestSubject = testSrc:
        let
          rel = relCommands testSrc;
          subjRel = lib.replaceStrings [ "/tests/test_" ] [ "/" ] rel;
        in
        if !(lib.hasInfix "/tests/test_" rel) then
          throw "flake.nix: commands/${rel} is not named tests/test_<leaf>.nim"
        else if !(builtins.pathExists (axCommandsDir + "/${subjRel}")) then
          throw "flake.nix: commands/${rel} has no subject module at commands/${subjRel}"
        else axCommandsDir + "/${subjRel}";

      axTests = map
        (t:
          let
            rel = relCommands t;
            name = "test_" + lib.concatStringsSep "_"
              (lib.splitString "/" (lib.removeSuffix ".nim"
                (lib.replaceStrings [ "/tests/test_" ] [ "/" ] rel)));
          in
          mkNimTest {
            inherit name;
            testPath = "commands/${rel}";
            extraFiles = [ (axTestSubject t) ];
          })
        (lib.filter
          (p: lib.hasSuffix ".nim" (toString p)
              && lib.hasInfix "/tests/" (toString p))
          (lib.filesystem.listFilesRecursive axCommandsDir));

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

      packages.${system} = {
        nim-functions = pkgs.symlinkJoin {
          name = "nixotic-nim-functions";
          paths = pkgs.lib.mapAttrsToList mkNimFunction checkedNimFunctionBinaries;
        };
        ax = axPackage;
      };

      checks.${system} =
        # One check per test file, keyed by its module name, so `nix flake
        # check` reports the failing suite by name and reruns only what changed.
        (lib.listToAttrs (map (d: lib.nameValuePair d.pname d) (nimTests ++ axTests)))
        // {
          ax-smoke =
            pkgs.runCommand "nixotic-ax-smoke"
              { nativeBuildInputs = [ pkgs.jq pkgs.zsh ]; }
              ''
                ax=${axPackage}

                # commands/ sources <-> libexec/ax binaries, both directions
                expected="${lib.concatStringsSep " " (map binName checkedCommandSources)}"
                actual="$(cd $ax/libexec/ax && echo *)"
                for name in $expected; do
                  case " $actual " in
                    *" $name "*) ;;
                    *) echo "error: $name expected from commands/ but not in libexec/ax" >&2
                       exit 1 ;;
                  esac
                done
                for name in $actual; do
                  case " $expected " in
                    *" $name "*) ;;
                    *) echo "error: $name in libexec/ax but has no commands/ source" >&2
                       exit 1 ;;
                  esac
                done

                # registry <-> libexec/ax, both directions
                jq -r '.[].path | "ax-" + join("-")' $ax/share/ax/registry.json \
                  | sort > registry-bins
                printf '%s\n' $actual | sort > libexec-bins
                diff -u registry-bins libexec-bins > /dev/null || {
                  echo "error: registry.json and libexec/ax disagree" >&2
                  exit 1
                }

                # every registry leaf is a lexicon verb or report-noun
                jq -e --slurpfile lex ${nimDir}/lexicon.json '
                  ([.[].path | last]
                   - ([$lex[0].verbs[].name] + $lex[0].reportNouns)) == []
                ' $ax/share/ax/registry.json > /dev/null || {
                  echo "error: registry contains a leaf outside the lexicon" >&2
                  exit 1
                }

                # driver dispatch works: --help exits 0 for every command
                jq -r '.[].path | join(" ")' $ax/share/ax/registry.json \
                  | while read -r cmd; do
                      if ! helpOutput="$($ax/bin/ax $cmd --help 2>&1)"; then
                        echo "error: ax $cmd --help exited non-zero, output follows:" >&2
                        printf '%s\n' "$helpOutput" >&2
                        exit 1
                      fi
                    done || exit 1

                # the generated completion parses (+X forces the load)
                zsh -fc "fpath=($ax/share/zsh/site-functions \$fpath); autoload -Uz +X _ax" || {
                  echo "error: generated _ax failed to parse" >&2
                  exit 1
                }

                touch $out
              '';
          nim-functions-smoke =
            pkgs.runCommand "nixotic-nim-functions-smoke"
              { nativeBuildInputs = [ self.packages.${system}.nim-functions ]; }
              ''
                expected="${lib.concatStringsSep " " (builtins.attrNames checkedNimFunctionBinaries)}"
                actual="$(cd ${self.packages.${system}.nim-functions}/bin && echo *)"

                for name in $expected; do
                  case " $actual " in
                    *" $name "*) ;;
                    *) echo "error: $name declared in nimFunctionBinaries but not built" >&2
                       exit 1 ;;
                  esac
                done

                # Catches a symlinkJoin collision or a stray file in an output
                # bin/ — the declared-vs-built direction above cannot see either.
                for name in $actual; do
                  case " $expected " in
                    *" $name "*) ;;
                    *) echo "error: $name built but not declared in nimFunctionBinaries" >&2
                       exit 1 ;;
                  esac
                done

                for name in $expected; do
                  bin="${self.packages.${system}.nim-functions}/bin/$name"
                  if ! helpOutput="$("$bin" --help 2>&1)"; then
                    echo "error: $name --help exited non-zero, output follows:" >&2
                    printf '%s\n' "$helpOutput" >&2
                    exit 1
                  fi
                done

                touch $out
              '';
        };

      devShells.${system}.default = pkgs.mkShell {
        name = "nixotic-nim";
        packages = nimToolchain;
      };
    };
}
