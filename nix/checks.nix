# Flake checks: one derivation per Nim test file plus the ax integration
# and smoke suites.
{ pkgs, lib, nimDir, nim, ax }:
let
  inherit (nim) nimShared nimToolchain nimTests;
  inherit (ax) axVersion axDriver axPackage axTests binName checkedCommandSources;
in
# One check per test file, keyed by its module name, so `nix flake
# check` reports the failing suite by name and reruns only what changed.
(lib.listToAttrs (map (d: lib.nameValuePair d.pname d) (nimTests ++ axTests)))
// {
  ax-integration = pkgs.stdenv.mkDerivation {
    pname = "nixotic-ax-integration";
    version = axVersion;
    src = lib.fileset.toSource {
      root = nimDir;
      fileset = lib.fileset.union nimShared (nimDir + "/tests");
    };
    nativeBuildInputs = nimToolchain ++ [ pkgs.jq ];
    AX_DRIVER = "${axDriver}/bin/ax";
    buildPhase = ''
      runHook preBuild
      timeout --kill-after=5s 180s bash tests/integration.sh
      runHook postBuild
    '';
    installPhase = "touch $out";
  };
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
        jq -e --slurpfile lex ${nimDir + "/lexicon.json"} '
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
}
