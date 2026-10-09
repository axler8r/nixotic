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

suite "input.resolveItems":
  test "positionals win over piped input":
    withInput("piped\n", proc(f: File) =
      check resolveItems(@["given"], f) == @["given"])

  test "falls back to piped input when no positionals":
    withInput("x\ny\n", proc(f: File) =
      check resolveItems(@[], f) == @["x", "y"])
