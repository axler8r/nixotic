# Nim build plumbing shared by the ax command tree and the flake checks.
{ pkgs, lib, nimDir }:
let
  # nim.cfg + lib/*.nim + lexicon.json shared by every command.
  # Tests and their helper are excluded from production compilation.
  # lexicon.json rides along because
  # lib/lexicon.nim embeds it with staticRead.
  nimShared = lib.fileset.difference
    (lib.fileset.unions
      [ (nimDir + "/nim.cfg") (nimDir + "/lib") (nimDir + "/lexicon.json") ])
    (lib.fileset.unions [ (nimDir + "/lib/tests") (nimDir + "/lib/testing.nim") ]);

  nimTestShared = lib.fileset.union nimShared (nimDir + "/lib/testing.nim");

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

  # One derivation per test file, mirroring mkAxCommand's granularity:
  # a test only rebuilds when its own fileset changes, and Nix runs the
  # suites in parallel rather than serially in a single buildPhase.
  #
  # Deliberately built WITHOUT -d:release for readable stack/line traces.
  # Nim release mode retains assertions; doAssert is always enabled.
  mkNimTest = { name, testPath, extraFiles ? [ ] }:
    pkgs.stdenv.mkDerivation {
      pname = "nixotic-nim-test-${name}";
      version = "0.1.0";
      src = lib.fileset.toSource {
        root = nimDir;
        fileset = lib.fileset.unions ([ nimTestShared (nimDir + "/${testPath}") ] ++ extraFiles);
      };
      nativeBuildInputs = nimToolchain;
      buildPhase = ''
        runHook preBuild
        nim c --parallelBuild:"$NIX_BUILD_CORES" \
          --nimcache:"$TMPDIR/nimcache" -o:"$TMPDIR/${name}" ${testPath}
        runHook postBuild
      '';
      doCheck = true;
      checkPhase = ''
        runHook preCheck
        timeout --kill-after=5s 120s "$TMPDIR/${name}"
        runHook postCheck
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

  nimTests =
    map
      (f: mkNimTest {
        name = lib.removeSuffix ".nim" f;
        testPath = "lib/tests/${f}";
      })
      (nimTestFiles "lib/tests");
in
{
  inherit nimShared nimTestShared nimToolchain mkNimTest nimTestFiles nimTests;
}
