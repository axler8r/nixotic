import std/[unittest, os, strutils]
import "../devenv"
import "../testing"

suite "devenv.formatPackageLines":
  test "one line per name, 12-space indent, given prefix":
    check formatPackageLines("pkgs.", @["jq", "ripgrep"]) ==
      @["            pkgs.jq", "            pkgs.ripgrep"]

  test "a beamPackages-style prefix works the same way":
    check formatPackageLines("pkgs.beamPackages.", @["elixir"]) ==
      @["            pkgs.beamPackages.elixir"]

  test "empty names yields an empty seq":
    check formatPackageLines("pkgs.", newSeq[string]()) == newSeq[string]()

suite "devenv.flakeNixContent":
  test "renders name, packages, and no env-attrs block by default":
    let content = flakeNixContent("myproj", @["            pkgs.jq"])
    check content.contains("description = \"myproj development environment\";")
    check content.contains("name = \"myproj\";")
    check content.contains("            pkgs.jq")
    check content.contains("systems = [ \"x86_64-linux\" \"aarch64-linux\" \"x86_64-darwin\" \"aarch64-darwin\" ];")
    check content.endsWith("}\n")
    check not content.contains("DOTNET")

  test "envAttrs, when given, is inserted right after the packages list closes":
    let content = flakeNixContent("myproj", @["            pkgs.dotnet-sdk_9"],
      "\n          DOTNET_CLI_TELEMETRY_OPTOUT = \"1\";\n          DOTNET_NOLOGO = \"1\";")
    let expectedTail = "          ];\n          DOTNET_CLI_TELEMETRY_OPTOUT = \"1\";\n          DOTNET_NOLOGO = \"1\";\n        };\n"
    check content.contains(expectedTail)

  test "exact full content for a two-package, no-env-attrs case":
    let content = flakeNixContent("demo", @["            pkgs.jq", "            pkgs.fd"])
    let expected = """{
  description = "demo development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, ... }: {
        devShells.default = pkgs.mkShell {
          name = "demo";
          packages = [
            pkgs.jq
            pkgs.fd
          ];
        };
      };
    };
}
"""
    check content == expected

suite "devenv.scaffoldDevEnvironment":
  test "an existing flake.nix is an error, nothing else is touched":
    let dir = getTempDir() / "test_devenv_scaffold_exists"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / "flake.nix", "existing content")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "test_devenv_scaffold_exists_out.txt"
    let f = open(outPath, fmWrite)
    let code = scaffoldDevEnvironment("new content", f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("flake.nix already exists")
    check flakeContent == "existing content"
    check not fileExists(dir / ".envrc")

  test "an existing .envrc is an error, but flake.nix has already been (over)written":
    # Mirrors the zsh original exactly: it checks/writes flake.nix fully
    # (including the "Created flake.nix" message) BEFORE ever checking
    # .envrc -- so a pre-existing .envrc still leaves a freshly written
    # flake.nix behind even though the function goes on to fail.
    let dir = getTempDir() / "test_devenv_scaffold_envrc_exists"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / ".envrc", "existing")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let outPath = getTempDir() / "test_devenv_scaffold_envrc_exists_out.txt"
    let f = open(outPath, fmWrite)
    let code = scaffoldDevEnvironment("new content", f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let flakeContent = readFile(dir / "flake.nix")
    removeFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Created flake.nix")
    check content.contains(".envrc already exists")
    check flakeContent == "new content"

  test "no .gitignore present: no gitignore message, no crash":
    let dir = getTempDir() / "test_devenv_scaffold_no_gitignore"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    let outPath = getTempDir() / "test_devenv_scaffold_no_gitignore_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = scaffoldDevEnvironment("content", f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check not content.contains("gitignore")

  test "a .gitignore without .direnv gets it appended, with a message":
    let dir = getTempDir() / "test_devenv_scaffold_gitignore_append"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / ".gitignore", "node_modules\n")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    let outPath = getTempDir() / "test_devenv_scaffold_gitignore_append_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = scaffoldDevEnvironment("content", f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let gitignore = readFile(dir / ".gitignore")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("Added .direnv to .gitignore")
    check gitignore == "node_modules\n.direnv\n"

  test "a .gitignore that already has .direnv is left untouched, no message":
    let dir = getTempDir() / "test_devenv_scaffold_gitignore_present"
    removeDir(dir)
    createDir(dir)
    writeFile(dir / ".gitignore", "node_modules\n.direnv\n")
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    writeFakeExe(dir, "direnv", "exit 0")
    let outPath = getTempDir() / "test_devenv_scaffold_gitignore_present_out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = scaffoldDevEnvironment("content", f, f)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let gitignore = readFile(dir / ".gitignore")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check not content.contains("gitignore")
    check gitignore == "node_modules\n.direnv\n"

  test "contract: direnv allow's exit code is never checked -- success is always reported":
    let dir = getTempDir() / "test_devenv_scaffold_direnv_fails"
    removeDir(dir)
    createDir(dir)
    let savedDir = getCurrentDir()
    setCurrentDir(dir)
    let rec = newRecordingRunner(exitCode = 1)
    let outPath = getTempDir() / "test_devenv_scaffold_direnv_fails_out.txt"
    let f = open(outPath, fmWrite)
    let code = scaffoldDevEnvironment("content", f, f, rec.runner)
    f.close()
    setCurrentDir(savedDir)
    let content = readFile(outPath)
    let flakeContent = readFile(dir / "flake.nix")
    let envrc = readFile(dir / ".envrc")
    removeFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("Environment activated")
    check flakeContent == "content"
    check envrc == "use flake\n"
    check rec.calls.len == 1
    check rec.calls[0].cmd == "direnv"
    check rec.calls[0].args == @["allow"]
