# Flake checks: native configuration syntax, Nim tests, and ax integration.
{ pkgs, lib, nimDir, nim, ax }:
let
  inherit (nim) nimShared nimToolchain nimTests;
  inherit (ax) axVersion axDriver axPackage axTests binName checkedCommandSources;
in
# One check per test file, keyed by its module name, so `nix flake
# check` reports the failing suite by name and reruns only what changed.
(lib.listToAttrs (map (d: lib.nameValuePair d.pname d) (nimTests ++ axTests)))
// {
  home-config =
    let
      tmux = (import ../home/tmux.nix { config = {}; inherit pkgs; }).programs.tmux;
      dircolors = (import ../home/dircolors.nix { config = {}; inherit pkgs; }).programs.dircolors;
      starship = (import ../home/starship.nix { config = {}; inherit pkgs; }).programs.starship;
      tmuxConfig = pkgs.writeText "tmux.conf" tmux.extraConfig;
      dircolorsConfig = pkgs.writeText "dir_colors" dircolors.extraConfig;
      starshipConfig = (pkgs.formats.toml {}).generate "starship.toml" starship.settings;
    in
    pkgs.runCommand "nixotic-home-config"
      { nativeBuildInputs = [ pkgs.luajit pkgs.tmux pkgs.starship pkgs.coreutils ]; }
      ''
        export HOME="$TMPDIR/home"
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_CACHE_HOME="$HOME/.cache"
        export TERM=xterm-256color
        mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

        luajit -e 'assert(loadfile("${../files/neovim/init.lua}")); assert(loadfile("${../files/neovim/plugins.lua}"))'
        dircolors -b ${dircolorsConfig} > /dev/null

        tmux -S "$TMPDIR/tmux.sock" -f /dev/null new-session -d -s config-check
        trap 'tmux -S "$TMPDIR/tmux.sock" kill-server 2>/dev/null || true' EXIT
        tmux -S "$TMPDIR/tmux.sock" source-file -n ${tmuxConfig}

        for config in ${../files/starship/starship.toml} ${starshipConfig}; do
          STARSHIP_CONFIG="$config" STARSHIP_LOG=warn starship print-config > /dev/null 2> starship.log
          if test -s starship.log; then
            cat starship.log >&2
            exit 1
          fi
        done

        touch "$out"
      '';

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
