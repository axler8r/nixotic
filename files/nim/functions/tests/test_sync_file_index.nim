import std/[unittest, os, strutils]
import "../SyncFileIndex"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

suite "Sync-FileIndex run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_sync_file_index_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Sync-FileIndex")

  test "fails when the index file does not exist":
    let dir = mkTmpDir("sfi_missing_track")
    check run(@[dir]) == 1
    removeDir(dir)

  test "reports already in sync and leaves the file untouched":
    let dir = mkTmpDir("sfi_in_sync")
    writeFile(dir / "a.txt", "x")
    writeFile(dir / "_TRACK", "[x] a.txt\n")
    let code = run(@[dir])
    let content = readFile(dir / "_TRACK")
    removeDir(dir)
    check code == 0
    check content == "[x] a.txt\n"

  test "adds a new on-disk file with an empty mark":
    let dir = mkTmpDir("sfi_added")
    writeFile(dir / "a.txt", "x")
    writeFile(dir / "b.txt", "x")
    writeFile(dir / "_TRACK", "[x] a.txt\n")
    let code = run(@[dir])
    let content = readFile(dir / "_TRACK")
    removeDir(dir)
    check code == 0
    check "[x] a.txt" in content
    check "[ ] b.txt" in content

  test "removes an entry whose file no longer exists on disk":
    let dir = mkTmpDir("sfi_removed")
    writeFile(dir / "a.txt", "x")
    writeFile(dir / "_TRACK", "[x] a.txt\n[ ] gone.txt\n")
    let code = run(@[dir])
    let content = readFile(dir / "_TRACK")
    removeDir(dir)
    check code == 0
    check "gone.txt" notin content
    check "[x] a.txt" in content

  test "dry-run reports changes without writing the file":
    let dir = mkTmpDir("sfi_dryrun")
    writeFile(dir / "a.txt", "x")
    writeFile(dir / "b.txt", "x")
    writeFile(dir / "_TRACK", "[x] a.txt\n")
    let code = run(@[dir, "--dry-run"])
    let content = readFile(dir / "_TRACK")
    removeDir(dir)
    check code == 0
    check content == "[x] a.txt\n"

  test "excludes files matching TRACK_EXCLUDE_GLOB":
    let dir = mkTmpDir("sfi_excluded")
    writeFile(dir / "a.txt", "x")
    writeFile(dir / "ignore.sh", "x")
    writeFile(dir / "_TRACK", "[x] a.txt\n")
    putEnv("TRACK_EXCLUDE_GLOB", "*.sh")
    let code = run(@[dir])
    delEnv("TRACK_EXCLUDE_GLOB")
    let content = readFile(dir / "_TRACK")
    removeDir(dir)
    check code == 0
    check "ignore.sh" notin content

  test "accepts an explicit -f index file path":
    let dir = mkTmpDir("sfi_explicit_f")
    writeFile(dir / "a.txt", "x")
    writeFile(dir / "b.txt", "x")
    let trackPath = dir / "_TRACK"
    writeFile(trackPath, "[x] a.txt\n")
    let code = run(@["-f", trackPath])
    let content = readFile(trackPath)
    removeDir(dir)
    check code == 0
    check "[ ] b.txt" in content

  test "unwritable index file is a reported error, not a traceback":
    let dir = getTempDir() / "test_sync_file_index_readonly"
    removeDir(dir)
    createDir(dir)
    let track = dir / "_TRACK"
    writeFile(track, "[ ] gone.txt\n")
    writeFile(dir / "present.txt", "")
    setFilePermissions(track, {fpUserRead})
    setFilePermissions(dir, {fpUserRead, fpUserExec})
    let outPath = getTempDir() / "test_sync_file_index_readonly_out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@["-f", track], f, f)
    f.close()
    let content = readFile(outPath)
    setFilePermissions(dir, {fpUserRead, fpUserWrite, fpUserExec})
    setFilePermissions(track, {fpUserRead, fpUserWrite})
    removeDir(dir)
    removeFile(outPath)
    check code == 1
    check content.contains("Error: ")
    check not content.contains("Traceback")
