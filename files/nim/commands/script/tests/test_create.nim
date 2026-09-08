import std/[unittest, os, strutils]
import "../create"
import "../../../lib/testing"

proc mkTmpPath(name: string): string =
  result = getTempDir() / name
  if fileExists(result):
    removeFile(result)

proc withStdin(content: string, body: proc(f: File)) =
  let tmp = getTempDir() / "test_write_executable_stdin.txt"
  writeFile(tmp, content)
  let f = open(tmp, fmRead)
  try:
    body(f)
  finally:
    f.close()
    removeFile(tmp)

suite "ax script create run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_write_executable_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax script create")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_write_executable_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax script create")

  test "missing filename arg exits 64":
    let tmp = getTempDir() / "test_write_executable_missing_arg.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    removeFile(tmp)
    check code == 64

  test "last positional arg wins when multiple are given":
    let target = mkTmpPath("test_write_executable_last_wins")
    let decoy = mkTmpPath("test_write_executable_decoy")
    withStdin("echo hi\n", proc(inf: File) =
      let code = run(@[decoy, target], stdout, stderr, inf)
      check code == 0
    )
    check fileExists(target)
    check not fileExists(decoy)
    removeFile(target)

  test "writes shebang, blank line, content, trailing newline -- stdin WITH trailing newline":
    let target = mkTmpPath("test_write_executable_with_nl")
    withStdin("echo hello\n", proc(inf: File) =
      let code = run(@[target], stdout, stderr, inf)
      check code == 0
    )
    let written = readFile(target)
    removeFile(target)
    check written == "#! /usr/bin/env zsh\n\necho hello\n"

  test "writes shebang, blank line, content, trailing newline -- stdin WITHOUT trailing newline":
    let target = mkTmpPath("test_write_executable_without_nl")
    withStdin("echo hello", proc(inf: File) =
      let code = run(@[target], stdout, stderr, inf)
      check code == 0
    )
    let written = readFile(target)
    removeFile(target)
    check written == "#! /usr/bin/env zsh\n\necho hello\n"

  test "multiple trailing newlines are all stripped, matching zsh $(cat) semantics":
    let target = mkTmpPath("test_write_executable_multi_nl")
    withStdin("echo hello\n\n\n", proc(inf: File) =
      let code = run(@[target], stdout, stderr, inf)
      check code == 0
    )
    let written = readFile(target)
    removeFile(target)
    check written == "#! /usr/bin/env zsh\n\necho hello\n"

  test "interior blank lines in stdin are preserved":
    let target = mkTmpPath("test_write_executable_interior_blank")
    withStdin("echo a\n\necho b\n", proc(inf: File) =
      let code = run(@[target], stdout, stderr, inf)
      check code == 0
    )
    let written = readFile(target)
    removeFile(target)
    check written == "#! /usr/bin/env zsh\n\necho a\n\necho b\n"

  test "file is executable after writing":
    let target = mkTmpPath("test_write_executable_perm")
    withStdin("echo hi\n", proc(inf: File) =
      discard run(@[target], stdout, stderr, inf)
    )
    let perms = getFilePermissions(target)
    removeFile(target)
    check fpUserExec in perms

  test "prints created-executable-script message to stdout":
    let target = mkTmpPath("test_write_executable_message")
    let outTmp = getTempDir() / "test_write_executable_message_out.txt"
    let outf = open(outTmp, fmWrite)
    withStdin("echo hi\n", proc(inf: File) =
      discard run(@[target], outf, stderr, inf)
    )
    outf.close()
    let message = readFile(outTmp)
    removeFile(target)
    removeFile(outTmp)
    check message == "Created executable script: " & target & "\n"

  test "unwritable target path is a reported error, not a traceback":
    let dir = getTempDir() / "test_write_executable_readonly"
    removeDir(dir)
    createDir(dir)
    let target = dir / "script"
    let outPath = getTempDir() / "test_write_executable_readonly_out.txt"
    let inPath = getTempDir() / "test_write_executable_readonly_in.txt"
    writeFile(inPath, "echo hello\n")
    writeFile(outPath, "")
    var code = 0
    var content = ""
    try:
      setFilePermissions(dir, {fpUserRead, fpUserExec})
      let f = open(outPath, fmWrite)
      let inf = open(inPath, fmRead)
      code = run(@[target], f, f, inf)
      f.close()
      inf.close()
      content = readFile(outPath)
    finally:
      # Restore permissions and remove the fixtures unconditionally, even if
      # run() regresses and raises -- otherwise a future guard regression
      # leaves an unwritable directory under getTempDir() that poisons later
      # local and CI runs with unrelated permission-denied errors.
      setFilePermissions(dir, {fpUserRead, fpUserWrite, fpUserExec})
      removeDir(dir)
      removeFile(outPath)
      removeFile(inPath)
    check code == 1
    check content.contains("Error: ")
    check content.contains(target)
    check not content.contains("Traceback")

  test "contract: chmod is called with +x <target>":
    let target = mkTmpPath("test_write_executable_contract")
    let rec = newRecordingRunner(exitCode = 0)
    var code: int
    withStdin("echo hi\n", proc(inf: File) =
      code = run(@[target], stdout, stderr, inf, rec.runner)
    )
    removeFile(target)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "chmod"
    check rec.calls[0].args == @["+x", target]
