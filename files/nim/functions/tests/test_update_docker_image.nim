import std/[unittest, os, strutils]
import "../UpdateDockerImage"

suite "Update-DockerImage filterImages":
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

suite "Update-DockerImage run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_update_docker_image_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Update-DockerImage")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_update_docker_image_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Update-DockerImage")

  # The checkDeps failure path (docker missing from $PATH) is not exercised
  # here: docker is present on $PATH in this sandbox/devShell, so a genuine
  # "missing docker" case can't be constructed without faking $PATH in a way
  # that would also hide other coreutils the test runner needs. See the
  # migration report for detail.

  # The live-pull loop (docker image list / docker pull) is not exercised by
  # these tests: it requires a real docker daemon, which isn't reliably
  # available in this sandbox. It's covered by manual/production use only,
  # consistent with the conventions doc's accepted gaps for un-mockable
  # subprocess passthrough.
