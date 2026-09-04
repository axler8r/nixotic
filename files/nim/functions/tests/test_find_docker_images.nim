import std/[unittest, os, strutils]
import "../FindDockerImages"
import "../../lib/testing"

suite "Find-DockerImages parseArgs":
  test "no args: raw false, empty search term":
    let p = parseArgs(@[])
    check p.raw == false
    check p.searchTerm == ""

  test "a single non-flag arg becomes the search term":
    check parseArgs(@["nginx"]).searchTerm == "nginx"

  test "multiple non-flag args are joined with spaces, in order":
    check parseArgs(@["postgres", "official"]).searchTerm == "postgres official"

  test "--raw is excluded from the search term regardless of position":
    let p1 = parseArgs(@["--raw", "nginx"])
    check p1.raw == true
    check p1.searchTerm == "nginx"
    let p2 = parseArgs(@["nginx", "--raw"])
    check p2.raw == true
    check p2.searchTerm == "nginx"

suite "Find-DockerImages run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_find_docker_images_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Find-DockerImages")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_find_docker_images_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Find-DockerImages")

  test "missing search term is exit 1, error on errp, usage reminder on outp":
    let outTmp = getTempDir() / "test_find_docker_images_noterm_out.txt"
    let errTmp = getTempDir() / "test_find_docker_images_noterm_err.txt"
    let outf = open(outTmp, fmWrite)
    let errf = open(errTmp, fmWrite)
    let code = run(@[], outf, errf)
    outf.close()
    errf.close()
    let outContent = readFile(outTmp)
    let errContent = readFile(errTmp)
    removeFile(outTmp)
    removeFile(errTmp)
    check code == 1
    check errContent.contains("Missing search term")
    check outContent.contains("Usage: Find-DockerImages [--raw] <search-term>")

  test "missing search term is checked before checkDeps(docker)":
    # Mirrors the zsh original's ordering: the search-term check runs before
    # __ax_check_deps docker, so this outcome doesn't depend on docker being
    # on $PATH.
    let dir = getTempDir() / "deps_find_docker_images_noterm"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw"], f, f)
    f.close()
    removeDir(dir)
    check code == 1

  test "missing docker is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_find_docker_images"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["nginx"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: docker")

  test "contract: docker search receives the joined term, rows sorted descending by stars":
    let dir = getTempDir() / "contract_find_docker_images"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "docker", "")
    writeFakeExe(dir, "column", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "bitnami/nginx|100\nnginx|15000\nnginxinc/nginx-unprivileged|300\n")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw", "nginx"], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "docker"
    check rec.calls[0].args == @["search", "nginx", "--format={{.Name}}|{{.StarCount}}"]
    check rec.calls[1].cmd == "column"
    check rec.calls[1].input == "Name|Stars\n" &
      "nginx|15000\nnginxinc/nginx-unprivileged|300\nbitnami/nginx|100"
