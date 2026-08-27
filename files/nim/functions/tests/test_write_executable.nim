import std/[unittest, os, strutils]
import "../WriteExecutable"

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

suite "Write-Executable run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_write_executable_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Write-Executable")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_write_executable_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Write-Executable")

  test "missing filename arg exits 1":
    let tmp = getTempDir() / "test_write_executable_missing_arg.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    removeFile(tmp)
    check code == 1

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
