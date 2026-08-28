# These tests need `git` on $PATH at runtime: several fixtures shell out to
# a real `git init`/`git remote add` (via runGit below) to build the
# repositories/remotes that run() then inspects — see flake.nix's
# nim-functions-tests nativeBuildInputs.
import std/[unittest, os, osproc, strutils]
import "../InitializeClaudeProject"
import "../../lib/testing"

proc mkTmpDir(name: string): string =
  result = getTempDir() / name
  removeDir(result)
  createDir(result)

proc runGit(dir: string, args: varargs[string]) =
  let p = startProcess(findExe("git"), workingDir = dir, args = @args,
                        options = {poUsePath})
  discard p.waitForExit()
  p.close()

proc withTempHome(homeDir: string, body: proc()) =
  let oldHome = getEnv("HOME")
  putEnv("HOME", homeDir)
  try:
    body()
  finally:
    putEnv("HOME", oldHome)

suite "Initialize-ClaudeProject run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_icp_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: Initialize-ClaudeProject")

  test "fails on an unexpected argument":
    check run(@["extra"]) == 1

  test "fails when the current directory is not a git repository":
    let dir = mkTmpDir("icp_not_git")
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    let code = run(@[])
    setCurrentDir(oldDir)
    removeDir(dir)
    check code == 1

  test "fails when the git repository has no origin remote":
    let dir = mkTmpDir("icp_no_origin")
    runGit(dir, "init", "-q")
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    let code = run(@[])
    setCurrentDir(oldDir)
    removeDir(dir)
    check code == 1

  test "fails when the project template does not exist":
    let dir = mkTmpDir("icp_no_template")
    let home = mkTmpDir("icp_no_template_home")
    runGit(dir, "init", "-q")
    runGit(dir, "remote", "add", "origin", "https://example.invalid/repo.git")
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    var code = 0
    withTempHome(home, proc() =
      code = run(@[])
    )
    setCurrentDir(oldDir)
    removeDir(dir)
    removeDir(home)
    check code == 1

  test "writes .claude/axler8r.md and imports it from .claude/CLAUDE.md":
    let dir = mkTmpDir("icp_success")
    let home = mkTmpDir("icp_success_home")
    createDir(home / ".claude/templates/project")
    writeFile(home / ".claude/templates/project/axler8r.md", "template body\n")
    runGit(dir, "init", "-q")
    runGit(dir, "remote", "add", "origin", "https://example.invalid/repo.git")
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    var code = 0
    withTempHome(home, proc() =
      code = run(@[])
    )
    setCurrentDir(oldDir)
    let axContent = readFile(dir / ".claude/axler8r.md")
    let claudeMd = readFile(dir / ".claude/CLAUDE.md")
    removeDir(dir)
    removeDir(home)
    check code == 0
    check axContent == "template body\n"
    check claudeMd.contains("@axler8r.md")

  test "does not duplicate the import when CLAUDE.md already references it":
    let dir = mkTmpDir("icp_idempotent")
    let home = mkTmpDir("icp_idempotent_home")
    createDir(home / ".claude/templates/project")
    writeFile(home / ".claude/templates/project/axler8r.md", "template body\n")
    runGit(dir, "init", "-q")
    runGit(dir, "remote", "add", "origin", "https://example.invalid/repo.git")
    createDir(dir / ".claude")
    writeFile(dir / ".claude/CLAUDE.md", "@axler8r.md\n")
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    var code = 0
    withTempHome(home, proc() =
      code = run(@[])
    )
    setCurrentDir(oldDir)
    let claudeMd = readFile(dir / ".claude/CLAUDE.md")
    removeDir(dir)
    removeDir(home)
    check code == 0
    check claudeMd.count("@axler8r.md") == 1

  test "unwritable working directory is a reported error, not a traceback":
    let dir = mkTmpDir("icp_readonly")
    let home = mkTmpDir("icp_readonly_home")
    createDir(home / ".claude/templates/project")
    writeFile(home / ".claude/templates/project/axler8r.md", "template body\n")
    runGit(dir, "init", "-q")
    runGit(dir, "remote", "add", "origin", "https://example.invalid/repo.git")
    let saved = getCurrentDir()
    let outPath = getTempDir() / "test_initialize_claude_project_readonly_out.txt"
    writeFile(outPath, "")
    var code = 0
    var content = ""
    try:
      setCurrentDir(dir)
      setFilePermissions(dir, {fpUserRead, fpUserExec})
      let f = open(outPath, fmWrite)
      withTempHome(home, proc() =
        code = run(@[], f, f)
      )
      f.close()
      content = readFile(outPath)
    finally:
      # Restore permissions/cwd and remove the fixtures unconditionally, even
      # if run() regresses and raises -- otherwise a future guard regression
      # leaves an unwritable directory under getTempDir() that poisons later
      # local and CI runs with unrelated permission-denied errors.
      setFilePermissions(dir, {fpUserRead, fpUserWrite, fpUserExec})
      setCurrentDir(saved)
      removeDir(dir)
      removeDir(home)
      removeFile(outPath)
    # Reaching the createDir call requires the home template to exist; if it
    # does not, the function exits earlier with its own error. Both are
    # acceptable outcomes here -- what must NOT happen is a traceback.
    check code == 1
    check content.contains("Error: ")
    check content.contains(".claude/")
    check not content.contains("Traceback")

  test "contract: gitSucceeds probes git-dir then origin remote via runQuiet":
    # A RecordingRunner intercepts both `git` probes inside gitSucceeds, so
    # both report success (exitCode 0) regardless of the temp dir's real git
    # state; withTempHome points HOME at a template-less dir so the run
    # deterministically fails at the template-missing check right after,
    # pinning the exit code without depending on this machine's real HOME.
    let dir = mkTmpDir("icp_contract")
    let home = mkTmpDir("icp_contract_home")
    let rec = newRecordingRunner(exitCode = 0)
    let oldDir = getCurrentDir()
    setCurrentDir(dir)
    var code = 0
    withTempHome(home, proc() =
      code = run(@[], stdout, stderr, rec.runner)
    )
    setCurrentDir(oldDir)
    removeDir(dir)
    removeDir(home)
    check code == 1
    check rec.calls.len == 2
    check rec.calls[0].kind == "capture"
    check rec.calls[0].cmd == "git"
    check rec.calls[0].args == @["rev-parse", "--git-dir"]
    check rec.calls[1].kind == "capture"
    check rec.calls[1].cmd == "git"
    check rec.calls[1].args == @["remote", "get-url", "origin"]
