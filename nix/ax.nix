# The ax command tree: commands/<group>/[<subgroup>/]<leaf>.nim maps
# mechanically to binary ax-<group>[-<subgroup>]-<leaf>. Lowercase
# path segments make the mapping reversible, so no hand-maintained
# name table is needed; the eval-time checks below replace the old
# drift guard.
{ pkgs, lib, nimDir, nim }:
let
  inherit (nim) nimShared mkNimTest;

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
      throw "nix/ax.nix: ${lib.concatStringsSep "; " problems}"
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
        nim c -d:release --parallelBuild:"$NIX_BUILD_CORES" --nimcache:.nimcache \
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
      nim c -d:release -d:axVersion=${axVersion} \
        --parallelBuild:"$NIX_BUILD_CORES" --nimcache:.nimcache \
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
    cp ${nimDir + "/commands/groups.json"} $out/share/ax/groups.json
    "$out/bin/ax" self completion zsh > $out/share/zsh/site-functions/_ax
  '';

  # A command test's subject is derived from the test's own path
  # (commands/<dir>/tests/test_<leaf>.nim -> commands/<dir>/<leaf>.nim)
  # -- mechanical rather than content-parsed, unlike the retired
  # nimTestSubject import scraping.
  axTestSubjects = testSrc:
    let
      rel = relCommands testSrc;
      subjRel = lib.replaceStrings [ "/tests/test_" ] [ "/" ] rel;
    in
    if !(lib.hasInfix "/tests/test_" rel) then
      throw "nix/ax.nix: commands/${rel} is not named tests/test_<leaf>.nim"
    # The family safety matrix deliberately exercises all vault commands.
    else if rel == "vault/tests/test_safety.nim" then
      map (leaf: axCommandsDir + "/vault/${leaf}.nim")
        [ "create" "mount" "remove" "resize" "unmount" ]
    else if !(builtins.pathExists (axCommandsDir + "/${subjRel}")) then
      throw "nix/ax.nix: commands/${rel} has no subject module at commands/${subjRel}"
    else [ (axCommandsDir + "/${subjRel}") ];

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
        extraFiles = axTestSubjects t;
      })
    (lib.filter
      (p: lib.hasSuffix ".nim" (toString p)
          && lib.hasInfix "/tests/" (toString p))
      (lib.filesystem.listFilesRecursive axCommandsDir));
in
{
  inherit axVersion axCommandsDir relCommands commandPath binName
    checkedCommandSources mkAxCommand axDriver axPackage axTests;
}
