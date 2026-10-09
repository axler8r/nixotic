import std/[unittest, os, strutils]
import "../list"
import "../../../../lib/testing"

suite "ax net nfs list parseArgs":
  test "no args: server defaults to localhost, raw false":
    let p = parseArgs(@[])
    check p.server == "localhost"
    check p.raw == false
    check p.unknownOption == ""

  test "a single non-flag arg becomes the server":
    check parseArgs(@["nfs.example.com"]).server == "nfs.example.com"

  test "--raw sets the raw flag without touching server":
    let p = parseArgs(@["--raw", "192.168.1.10"])
    check p.raw == true
    check p.server == "192.168.1.10"

  test "an unrecognized flag is captured as unknownOption and stops parsing":
    let p = parseArgs(@["--bogus", "nfs.example.com"])
    check p.unknownOption == "--bogus"
    check p.server == "localhost"

suite "ax net nfs list classifyShowmountError":
  test "connection refused":
    check classifyShowmountError("clnt_create: RPC: Connection refused", "host1") ==
      "Connection refused. NFS server may not be running on 'host1'."

  test "no route to host":
    check classifyShowmountError("clnt_create: RPC: No route to host", "host1") ==
      "Cannot reach host 'host1'. Check network connectivity."

  test "host unreachable":
    check classifyShowmountError("clnt_create: RPC: Host is unreachable", "host1") ==
      "Cannot reach host 'host1'. Check network connectivity."

  test "unknown hostname":
    check classifyShowmountError("host1: Name or service not known", "host1") ==
      "Cannot resolve hostname 'host1'."

  test "permission denied":
    check classifyShowmountError("mount clntudp_create: Permission denied", "host1") ==
      "Permission denied when querying 'host1'."

  test "timed out":
    check classifyShowmountError("clnt_create: RPC: Timed out", "host1") ==
      "Connection to 'host1' timed out."

  test "falls back to the raw message for anything unrecognized":
    check classifyShowmountError("some other failure", "host1") ==
      "Failed to query NFS exports: some other failure"

suite "ax net nfs list splitFirstWhitespaceRun":
  test "replaces only the first whitespace run with a pipe":
    check splitFirstWhitespaceRun("/export/path   client1,client2") ==
      "/export/path|client1,client2"

  test "leaves a line with no whitespace untouched":
    check splitFirstWhitespaceRun("/export/path") == "/export/path"

suite "ax net nfs list run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_get_nfs_exports_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ax net nfs list")

  test "an unknown option is an error, exit 64, before checkDeps(showmount)":
    let tmp = getTempDir() / "test_get_nfs_exports_bogus.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--bogus"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 64
    check content.contains("Unknown option: --bogus")

  test "missing showmount is exit 2 with a Missing commands error":
    let dir = getTempDir() / "deps_get_nfs_exports"
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
    check content.contains("Missing commands: showmount")

  test "a showmount failure is classified and reported, exit 1":
    let dir = getTempDir() / "run_showmount_fail"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "showmount", "")
    let rec = newRecordingRunner(exitCode = 1, error = "clnt_create: RPC: Connection refused")
    let outPath = dir / "out.txt"
    let errPath = dir / "err.txt"
    let outf = open(outPath, fmWrite)
    let errf = open(errPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["host1"], outf, errf, rec.runner)
    outf.close()
    errf.close()
    let errContent = readFile(errPath)
    removeDir(dir)
    check code == 1
    check errContent.contains("Connection refused. NFS server may not be running on 'host1'.")

  test "an empty export list warns and returns 0":
    let dir = getTempDir() / "run_showmount_empty"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "showmount", "")
    let rec = newRecordingRunner(exitCode = 0, output = "Export list for host1:\n")
    let outPath = dir / "out.txt"
    let errPath = dir / "err.txt"
    let outf = open(outPath, fmWrite)
    let errf = open(errPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["host1"], outf, errf, rec.runner)
    outf.close()
    errf.close()
    let errContent = readFile(errPath)
    removeDir(dir)
    check code == 0
    check errContent.contains("No NFS exports found on 'host1'.")

  test "contract: exports are reformatted and rendered via table, header line dropped":
    let dir = getTempDir() / "run_showmount_ok"
    removeDir(dir)
    createDir(dir)
    writeFakeExe(dir, "showmount", "")
    let rec = newRecordingRunner(exitCode = 0,
      output = "Export list for host1:\n/data       192.168.1.0/24\n/backups    10.0.0.5\n")
    let outPath = dir / "out.txt"
    let errPath = dir / "err.txt"
    let outf = open(outPath, fmWrite)
    let errf = open(errPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["--raw", "host1"], outf, errf, rec.runner)
    outf.close()
    errf.close()
    let errContent = readFile(errPath)
    removeDir(dir)
    check code == 0
    check rec.calls.len == 2
    check rec.calls[0].cmd == "showmount"
    check rec.calls[0].args == @["-e", "host1"]
    check rec.calls[1].cmd == "column"
    check rec.calls[1].input == "Export|Clients\n/data|192.168.1.0/24\n/backups|10.0.0.5\n"
    check errContent.contains("Found 2 export(s) on 'host1'.")
