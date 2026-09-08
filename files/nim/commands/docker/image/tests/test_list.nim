import std/[unittest, os, strutils]
import "../list"
import "../../../../lib/testing"

suite "ax docker image list parseDockerList":
  test "splits multiple rows on newlines":
    check parseDockerList("nginx|latest|2 days ago|abc123\npostgres|16|1 week ago|def456\n") ==
      @["nginx|latest|2 days ago|abc123", "postgres|16|1 week ago|def456"]

  test "drops the empty trailing line from a trailing newline":
    check parseDockerList("nginx|latest|2 days ago|abc123\n") == @["nginx|latest|2 days ago|abc123"]

  test "returns an empty seq for empty output":
    check parseDockerList("") == newSeq[string]()

suite "ax docker image list run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_docker_images_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker image list")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_docker_images_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker image list")

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_get_docker_images"
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

  test "characterization: lists non-dangling images, sorted, through table":
    let dir = getTempDir() / "char_get_docker_images"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "docker", """
""" & fakeRecorder(log) & """

case "$1 $2" in
  "image list") printf "postgres|16|1 week ago|def456\nnginx|latest|2 days ago|abc123\n" ;;
esac
""")
    writeFakeExe(dir, "column", fakeRecorder(dir / "column.log"))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @[
      "image list --format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.ID}} --filter=dangling=false"
    ]

  test "contract: docker is queried for non-dangling images, rows sorted, rendered via table":
    # `docker` is not a nativeBuildInput of the test sandbox (flake.nix), so
    # checkDeps(["docker"]) needs a stand-in on $PATH to succeed; its actual
    # invocation is intercepted by rec.runner, so the stub's content is never
    # run.
    let dir = getTempDir() / "contract_get_docker_images"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    writeFakeExe(dir, "column", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "postgres|16|1 week ago|def456\nnginx|latest|2 days ago|abc123\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "docker"
    check rec.calls[0].args == @["image", "list",
      "--format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.ID}}",
      "--filter=dangling=false"]
    check rec.calls[1].cmd == "column"
    check rec.calls[1].input == "Repository|Tag|Created|ID\n" &
      "nginx|latest|2 days ago|abc123\npostgres|16|1 week ago|def456\n"

  test "contract: --dangling switches to the dangling filter and adds the Size column":
    let dir = getTempDir() / "contract_docker_image_list_dangling"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    writeFakeExe(dir, "column", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "<none>|<none>|2 days ago|10MB|abc123\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw", "--dangling"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].args == @["image", "list",
      "--format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.Size}}|{{.ID}}",
      "--filter=dangling=true"]
    check rec.calls[1].input == "Repository|Tag|Created|Size|ID\n" &
      "<none>|<none>|2 days ago|10MB|abc123\n"
