import std/[unittest, os, strutils]
import "../RemoveDockerDanglingImages"

suite "Remove-DockerDanglingImages parseDockerList":
  test "splits multiple IDs on newlines":
    check parseDockerList("abc123\ndef456\n") == @["abc123", "def456"]

  test "drops the empty trailing line from a trailing newline":
    check parseDockerList("abc123\n") == @["abc123"]

  test "returns an empty seq for empty output":
    check parseDockerList("") == newSeq[string]()

  test "returns an empty seq for a single newline":
    check parseDockerList("\n") == newSeq[string]()

suite "Remove-DockerDanglingImages run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_remove_docker_dangling_images_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Remove-DockerDanglingImages")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_remove_docker_dangling_images_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Remove-DockerDanglingImages")

  # The checkDeps failure path (docker missing from $PATH) is not exercised
  # here: docker is present on $PATH in this sandbox/devShell, so a genuine
  # "missing docker" case can't be constructed without faking $PATH in a way
  # that would also hide other coreutils the test runner needs.

  # The live `docker image list` / `docker rmi` calls are not exercised by
  # these tests: they require a real docker daemon, which isn't reliably
  # available in this sandbox. Covered by manual/production use only,
  # consistent with the conventions doc's accepted gaps for un-mockable
  # subprocess passthrough.
