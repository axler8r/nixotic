import std/[unittest, os]
import "../fdscan"
import "../testing"

suite "fdscan.buildFdArgs":
  test "no extensions, not all: just --type f":
    check buildFdArgs(@[], false) == @["--type", "f"]

  test "allFlag adds --hidden --no-ignore":
    check buildFdArgs(@[], true) == @["--type", "f", "--hidden", "--no-ignore"]

  test "extensions become repeated --extension flags, in order":
    check buildFdArgs(@["py", "js"], false) ==
      @["--type", "f", "--extension", "py", "--extension", "js"]

suite "fdscan.findFiles":
  test "splits fd's output on newlines, dropping the trailing blank line":
    let rec = newRecordingRunner(exitCode = 0, output = "./a.py\n./b.py\n")
    let files = findFiles(rec.runner, "/some/dir", @[], false)
    check files == @["./a.py", "./b.py"]
    check rec.calls[0].cmd == "fd"
    check rec.calls[0].args == @["--type", "f", ".", "/some/dir"]

  test "returns an empty seq when fd finds nothing":
    let rec = newRecordingRunner(exitCode = 0, output = "")
    check findFiles(rec.runner, "/some/dir", @[], false) == newSeq[string]()

suite "fdscan.isTextMimeType":
  test "text/* is text":
    check isTextMimeType("text/plain") == true
    check isTextMimeType("text/x-python") == true

  test "application/json and application/xml are text":
    check isTextMimeType("application/json") == true
    check isTextMimeType("application/xml") == true

  test "anything else is not text":
    check isTextMimeType("application/octet-stream") == false
    check isTextMimeType("image/png") == false

suite "fdscan.mimeType":
  test "runs `file --brief --mime-type` on the given path, trimmed":
    let rec = newRecordingRunner(exitCode = 0, output = "text/plain\n")
    check mimeType(rec.runner, "/some/file.txt") == "text/plain"
    check rec.calls[0].cmd == "file"
    check rec.calls[0].args == @["--brief", "--mime-type", "/some/file.txt"]
