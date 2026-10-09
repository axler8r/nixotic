import std/[unittest, os, strutils, tempfiles]
import "../prune"
import "../../../../lib/testing"

suite "ax docker image prune parseDockerList":
  test "splits multiple IDs on newlines":
    check parseDockerList("abc123\ndef456\n") == @["abc123", "def456"]

  test "drops the empty trailing line from a trailing newline":
    check parseDockerList("abc123\n") == @["abc123"]

  test "returns an empty seq for empty output":
    check parseDockerList("") == newSeq[string]()

  test "returns an empty seq for a single newline":
    check parseDockerList("\n") == newSeq[string]()

suite "ax docker image prune run":
  test "invalid arguments cannot list or remove images":
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    for args in @[@["--bogus"], @["extra"], @["--dry-run"], @["-n"]]:
      let rec = newRecordingRunner()
      check run(args, f, f, rec.runner) == 64
      check rec.calls.len == 0

  test "failed listing cannot become empty success or removal":
    let dir = createTempDir("ax-image-prune-failure-", "")
    defer: removeDir(dir)
    writeFakeExe(dir, "docker", "")
    let f = open("/dev/null", fmWrite)
    defer: f.close()
    for listing in ["", "sha256:partial\n"]:
      let rec = newRecordingRunner(exitCode = 1, output = listing, error = "daemon unavailable")
      withPath(dir):
        check run(@[], f, f, rec.runner) == 1
      check rec.calls.len == 1

  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_docker_dangling_images_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker image prune")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_remove_docker_dangling_images_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker image prune")

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_remove_docker_dangling_images"
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

  test "characterization: lists then removes each dangling image":
    let dir = getTempDir() / "char_rm_dangling_images"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    # First call (image list) prints two ids; every call is logged.
    writeFakeExe(dir, "docker", """
""" & fakeRecorder(log) & """

case "$1 $2" in
  "image list") echo sha256:aaa; echo sha256:bbb ;;
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
      "image list --filter=dangling=true --format={{.ID}}",
      "rmi sha256:aaa",
      "rmi sha256:bbb"
    ]

  test "contract: lists dangling images then removes each returned ID":
    # `docker` is not a nativeBuildInput of the test sandbox (flake.nix), so
    # checkDeps(["docker"]) needs a stand-in on $PATH to succeed; its actual
    # invocation is intercepted by rec.runner, so the stub's content is never
    # run.
    let dir = getTempDir() / "contract_rm_dangling_images"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    let rec = newRecordingRunner(output = "sha256:aaa\nsha256:bbb\n")
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
    check rec.calls[0].args == @["image", "list", "--filter=dangling=true",
                                  "--format={{.ID}}"]
    check rec.calls[1].args == @["rmi", "sha256:aaa"]
    check rec.calls[2].args == @["rmi", "sha256:bbb"]
