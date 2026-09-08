import std/[unittest, os, strutils]
import "../list"
import "../../../../lib/testing"

suite "ax docker volume list parseDockerList":
  test "splits multiple rows on newlines":
    check parseDockerList("local|vol1\nlocal|vol2\n") == @["local|vol1", "local|vol2"]

  test "returns an empty seq for empty output":
    check parseDockerList("") == newSeq[string]()

suite "ax docker volume list run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_docker_dangling_volumes_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker volume list")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_get_docker_dangling_volumes_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax docker volume list")

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_get_docker_dangling_volumes"
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

  test "prints a plain message and returns 0 when there are no dangling volumes":
    let dir = getTempDir() / "empty_get_docker_dangling_volumes"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    let rec = newRecordingRunner(exitCode = 0, output = "")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--dangling"], f, f, rec.runner)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("No dangling volumes found.")
    check rec.calls.len == 1

  test "without --dangling the empty message and docker query drop the filter":
    let dir = getTempDir() / "empty_get_docker_all_volumes"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    let rec = newRecordingRunner(exitCode = 0, output = "")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[], f, f, rec.runner)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check content.contains("No volumes found.")
    check rec.calls.len == 1
    check rec.calls[0].args == @["volume", "list",
      "--format={{.Driver}}|{{.Name}}"]

  test "contract: docker is queried for dangling volumes, rendered via table, unsorted":
    let dir = getTempDir() / "contract_get_docker_dangling_volumes"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    writeFakeExe(dir, "column", "")
    let rec = newRecordingRunner(exitCode = 0, output = "local|vol-b\nlocal|vol-a\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw", "--dangling"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "docker"
    check rec.calls[0].args == @["volume", "list", "--filter=dangling=true",
      "--format={{.Driver}}|{{.Name}}"]
    check rec.calls[1].cmd == "column"
    # Deliberately NOT sorted — the zsh original never pipes this listing
    # through `sort`, unlike the two image-listing functions.
    check rec.calls[1].input == "Driver|Volume Name\nlocal|vol-b\nlocal|vol-a\n"
