import std/[os, unittest]
import "../input"

proc withInput(content: string, body: proc(f: File)) =
  let tmp = getTempDir() / "test_input_items.txt"
  writeFile(tmp, content)
  let f = open(tmp, fmRead)
  try:
    body(f)
  finally:
    f.close()
    removeFile(tmp)

suite "input.readPipedItems":
  test "one item per line, blank lines dropped, CR stripped":
    withInput("a\n\nb c\r\n  \nd", proc(f: File) =
      check readPipedItems(f) == @["a", "b c", "  ", "d"])

  test "empty non-terminal input yields no items":
    withInput("", proc(f: File) =
      check readPipedItems(f).len == 0)

  test "ANSI colour codes are stripped from items":
    withInput("\e[1;34mrepoA\e[0m\n\e[38;5;245mrepoB\e[0m\n", proc(f: File) =
      check readPipedItems(f) == @["repoA", "repoB"])

  test "multi-directory ls listing collapses to the directory names":
    withInput("repoA:\nbin\nREADME.md\n\nrepoB:\n\e[1;34mlib\e[0m\nmix.exs\n",
              proc(f: File) =
      check readPipedItems(f) == @["repoA", "repoB"])

  test "plain items after a listing block are still items":
    withInput("repoA:\nbin\n\nrepoB\n", proc(f: File) =
      check readPipedItems(f) == @["repoA", "repoB"])

suite "input.stripAnsi":
  test "removes CSI sequences and keeps text":
    check stripAnsi("\e[1;34mdir\e[0m \e[38;5;33m->\e[0m x") == "dir -> x"

  test "text without escapes is unchanged":
    check stripAnsi("plain/path") == "plain/path"

suite "input.resolveItems":
  test "positionals win over piped input":
    withInput("piped\n", proc(f: File) =
      check resolveItems(@["given"], f) == @["given"])

  test "falls back to piped input when no positionals":
    withInput("x\ny\n", proc(f: File) =
      check resolveItems(@[], f) == @["x", "y"])
