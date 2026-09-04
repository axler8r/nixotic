import std/[unittest, os, strutils]
import "../GetDanglingDockerImages"
import "../../lib/testing"

suite "Get-DanglingDockerImages parseDockerList":
  test "splits multiple rows on newlines":
    check parseDockerList("<none>|<none>|2 days ago|10MB|abc123\n") ==
      @["<none>|<none>|2 days ago|10MB|abc123"]

  test "returns an empty seq for empty output":
    check parseDockerList("") == newSeq[string]()

suite "Get-DanglingDockerImages run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_dangling_docker_images_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-DanglingDockerImages")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_dangling_docker_images_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Get-DanglingDockerImages")

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_get_dangling_docker_images"
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

  test "contract: docker is queried for dangling images, rows sorted, rendered via table":
    let dir = getTempDir() / "contract_get_dangling_docker_images"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    writeFakeExe(dir, "column", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "<none>|<none>|3 days ago|12MB|zzz999\n<none>|<none>|1 day ago|8MB|aaa111\n")
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
      "--format={{.Repository}}|{{.Tag}}|{{.CreatedSince}}|{{.Size}}|{{.ID}}",
      "--filter=dangling=true"]
    check rec.calls[1].cmd == "column"
    check rec.calls[1].input == "Repository|Tag|Created|Size|ID\n" &
      "<none>|<none>|1 day ago|8MB|aaa111\n<none>|<none>|3 days ago|12MB|zzz999"
