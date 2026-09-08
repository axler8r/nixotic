import std/[unittest, os, strutils]
import "../prune"
import "../../../../lib/testing"

suite "ax docker volume prune parseDockerList":
  test "splits multiple volume names on newlines":
    check parseDockerList("vol_a\nvol_b\n") == @["vol_a", "vol_b"]

  test "drops the empty trailing line from a trailing newline":
    check parseDockerList("vol_a\n") == @["vol_a"]

  test "returns an empty seq for empty output":
    check parseDockerList("") == newSeq[string]()

  test "returns an empty seq for a single newline":
    check parseDockerList("\n") == newSeq[string]()

suite "ax docker volume prune run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_docker_dangling_volumes_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker volume prune")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_remove_docker_dangling_volumes_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker volume prune")

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_remove_docker_dangling_volumes"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: docker")

  test "characterization: lists then removes each dangling volume":
    let dir = getTempDir() / "char_rm_dangling_volumes"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    # First call (volume list) prints two names; every call is logged.
    writeFakeExe(dir, "docker", """
""" & fakeRecorder(log) & """

case "$1 $2" in
  "volume list") echo vol_a; echo vol_b ;;
esac
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @[
      "volume list --quiet --filter=dangling=true",
      "volume rm vol_a",
      "volume rm vol_b"
    ]

  test "contract: lists dangling volumes then removes each returned name":
    # `docker` is not a nativeBuildInput of the test sandbox (flake.nix), so
    # checkDeps(["docker"]) needs a stand-in on $PATH to succeed; its actual
    # invocation is intercepted by rec.runner, so the stub's content is never
    # run.
    let dir = getTempDir() / "contract_rm_dangling_volumes"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    let rec = newRecordingRunner(output = "vol_a\nvol_b\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 3
    check rec.calls[0].cmd == "docker"
    check rec.calls[0].args == @["volume", "list", "--quiet",
                                  "--filter=dangling=true"]
    check rec.calls[1].args == @["volume", "rm", "vol_a"]
    check rec.calls[2].args == @["volume", "rm", "vol_b"]
