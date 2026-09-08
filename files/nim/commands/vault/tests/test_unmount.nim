import std/[unittest, os, strutils]
import "../unmount"
import "../../../lib/testing"

suite "ax vault unmount resolveTarget":
  test "an existing, currently-mounted directory resolves the mapper name from the source column":
    let mountOutput = "/dev/mapper/mydata on " & getTempDir() &
                       " type ext4 (rw,relatime)\n"
    let r = resolveTarget(getTempDir(), mountOutput)
    check r.invalid == false
    check r.mapperName == "mydata"
    check r.mountPoint == getTempDir()

  test "a bare name (no leading /) resolves its mount point from the mapper column":
    let mountOutput = "/dev/mapper/mydata on /home/user/Vaults/mydata type ext4 (rw)\n"
    let r = resolveTarget("mydata", mountOutput)
    check r.invalid == false
    check r.mapperName == "mydata"
    check r.mountPoint == "/home/user/Vaults/mydata"

  test "a bare name with no matching mount line still resolves the mapper name, empty mount point":
    let r = resolveTarget("mydata", "")
    check r.invalid == false
    check r.mapperName == "mydata"
    check r.mountPoint == ""

  test "an absolute path that is not an existing mounted directory is invalid":
    let r = resolveTarget("/definitely/not/mounted/xyz123", "")
    check r.invalid == true

  test "an existing directory that mount does not list is treated as a bare name if relative":
    # dirExists(target) is true but no " on <target> " line matches, and
    # target itself has no leading "/" (a relative dir), so it falls
    # through to the bare-name branch, exactly like the zsh original's
    # `&&`-then-`elif` chain. getCurrentDir() is always absolute, so this
    # needs a real relative directory: chdir into a fixture and resolve a
    # bare subdirectory name.
    let base = getTempDir() / "test_dismount_vault_relative_dir"
    removeDir(base)
    createDir(base / "reldir")
    let savedCwd = getCurrentDir()
    setCurrentDir(base)
    let mountOutput = "/dev/mapper/other on /somewhere type ext4 (rw)\n"
    let r = resolveTarget("reldir", mountOutput)
    setCurrentDir(savedCwd)
    removeDir(base)
    check r.invalid == false
    check r.mapperName == "reldir"

suite "ax vault unmount run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_dismount_vault_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax vault unmount")

  test "prints usage and returns 0 for -h (fixed: zsh original only checked --help)":
    let tmp = getTempDir() / "test_dismount_vault_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax vault unmount")

  test "no argument is an error":
    let tmp = getTempDir() / "test_dismount_vault_no_arg.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Missing required argument: name")

  test "dependencies are checked before capturing mount output":
    let dir = getTempDir() / "deps_dismount_vault_invalid"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "mount", "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["/definitely/not/mounted/xyz123"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands:")

  test "a resolvable but not-actually-open mapper is 'Vault mapper not found'":
    let dir = getTempDir() / "deps_dismount_vault_mapper_missing"
    removeDir(dir)
    createDir(dir)
    for exe in cmdSpec.deps:
      writeFakeExe(dir, exe, "exit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["definitely-not-a-real-mapper-xyz123"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 1
    check content.contains("Vault mapper not found")
  # Operational cleanup and open-but-unmounted recovery are in test_safety.
