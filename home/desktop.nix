{ pkgs, ... }:
# BEGIN nu-plugin-polars-ethnum-workaround — revert with Restore-NuPluginPolars

let
  # ethnum 1.5.2 (vendored via nushell's Cargo.lock) fails to compile on
  # rustc >=1.97 (transmutes `()` into `TryFromIntError`, sizes no longer
  # match). This rebuilds nu_plugin_polars with ethnum bumped to 1.5.3,
  # mirroring NixOS/nixpkgs#546343 exactly (patch + cargoHash both taken
  # from that PR). overrideAttrs doesn't work here: cargoPatches/cargoHash
  # only feed cargoDeps/patches at the original buildRustPackage call, not
  # on a later overrideAttrs. Tests skipped locally — upstream PR already
  # reports 212 package tests passing with this same patch.
  # Drop this once nixpkgs merges #546343 or a newer nushell release
  # carries the fix in its own Cargo.lock.
  nuPluginPolarsFixed = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "nu_plugin_polars";
    inherit (pkgs.nushell) version src;

    cargoPatches = [ ./patches/nu-plugin-polars-update-ethnum.patch ];
    cargoHash = "sha256-Cpv58bqpx1o0Dz2AykqzFY+PQE/Updr5MusQflpEF74=";
    doCheck = false;

    nativeBuildInputs = [
      pkgs.pkg-config
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.cc.isClang [ pkgs.rustPlatform.bindgenHook ];
    buildInputs = [ pkgs.openssl ];

    buildAndTestSubdir = "crates/nu_plugin_polars";

    meta = {
      description = "Nushell dataframe plugin commands based on polars";
      mainProgram = "nu_plugin_polars";
      license = pkgs.lib.licenses.mit;
    };
  });
in
# END nu-plugin-polars-ethnum-workaround

{
  imports = [
    ./base.nix
    ./atuin.nix
    ./bat.nix
    ./btop.nix
    ./claude.nix
    ./codex.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./gh.nix
    ./gnome.nix
    ./gpg.nix
    ./htop.nix
    ./jq.nix
    ./kitty.nix
    ./neovim.nix
    ./nh.nix
    ./nushell.nix
    ./ripgrep.nix
    ./stylix.nix
    ./vscode.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    # Version control & development
    gitflow
    parallel

    # AI coding assistants
    claude-code
    codex

    # Editors & text processing
    universal-ctags

    # Productivity CLI tools
    attr
    bfs
    choose
    curl
    dust
    duf
    fdupes
    gum
    jq
    lsof
    orpie
    p7zip
    pv
    sd
    socat
    strace
    tokei
    tree
    wget
    yq

    # Nushell plugins
    nushellPlugins.gstat
    nushellPlugins.highlight
    # nuPluginPolarsFixed
    nushellPlugins.query

    # Media
    ffmpeg
    mpv

    # Documents
    meowpdf
    typst
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
