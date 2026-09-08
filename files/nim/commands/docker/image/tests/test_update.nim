import std/[unittest, os, strutils]
import "../update"
import "../../../../lib/testing"

suite "ax docker image update filterImages":
  test "drops a line with a vsc prefix":
    check filterImages(@["vsc-foo:latest", "nginx:latest"]) == @["nginx:latest"]

  test "drops a line with an axler8r prefix":
    check filterImages(@["axler8r/tool:latest", "nginx:latest"]) == @["nginx:latest"]

  test "drops a line containing <none> anywhere":
    check filterImages(@["<none>:<none>", "repo:<none>", "nginx:latest"]) == @["nginx:latest"]

  test "drops a line containing devcontainer anywhere":
    check filterImages(@["myorg/devcontainer:latest", "nginx:latest"]) == @["nginx:latest"]

  test "keeps images that survive all filters":
    let input = @["nginx:latest", "postgres:16"]
    check filterImages(input) == input

  test "drops empty lines":
    check filterImages(@["nginx:latest", "", "postgres:16"]) == @["nginx:latest", "postgres:16"]

  test "prefix rules are anchored, not substring matches":
    # "notvsc:latest" contains "vsc" but does not start with it, so it must
    # survive -- unlike the substring rules for <none> and devcontainer.
    check filterImages(@["notvsc:latest", "notaxler8r:latest"]) ==
      @["notvsc:latest", "notaxler8r:latest"]

suite "ax docker image update run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_update_docker_image_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker image update")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_update_docker_image_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker image update")

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_update_docker_image"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["nginx:latest"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: docker")

  test "characterization: pulls each named image sequentially":
    let dir = getTempDir() / "char_update_docker_image"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    writeFakeExe(dir, "docker", fakeRecorder(log))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["nginx:latest", "postgres:16"], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @["pull nginx:latest", "pull postgres:16"]

  test "characterization: lists images with the repository:tag format string":
    let dir = getTempDir() / "char_update_docker_image_list"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    # Emit nothing on stdout so filterImages yields an empty list and the
    # function returns before any pull.
    writeFakeExe(dir, "docker", fakeRecorder(log))
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    removeDir(dir)
    check code == 0
    check calls == @["image list --format={{.Repository}}:{{.Tag}}"]

  test "contract: an explicit image list pulls exactly those images":
    # `docker` is not a nativeBuildInput of the test sandbox (flake.nix), so
    # checkDeps(["docker"]) needs a stand-in on $PATH to succeed; its actual
    # invocation is intercepted by rec.runner, so the stub's content is
    # never run.
    let dir = getTempDir() / "contract_update_docker_image"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["nginx:latest", "redis:7"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "docker"
    check rec.calls[0].args == @["pull", "nginx:latest"]
    check rec.calls[1].args == @["pull", "redis:7"]

  test "contract: a failed pull does not abort the remaining pulls":
    let dir = getTempDir() / "contract_update_docker_image_fail"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    let rec = newRecordingRunner(exitCode = 1)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["a:1", "b:2", "c:3"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    # The zsh original has no `|| return` in the loop; every image is
    # attempted and the failure only folds into the exit code.
    check rec.calls.len == 3
    check code == 1
