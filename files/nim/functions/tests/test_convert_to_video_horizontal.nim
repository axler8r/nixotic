import std/[unittest, os, strutils]
import "../ConvertToVideoHorizontal"
import "../../lib/testing"

# The hardware-acceleration fallback chain is characterized below with a
# fake ffmpeg on a fixture $PATH (see testing.writeFakeExe/withPath): the
# probes and the software fallback all invoke the same "ffmpeg" name, so
# the fake distinguishes calls by counting prior invocations logged so
# far. These are characterization tests against current behaviour, kept
# as a regression net for the later process-layer refactor.

suite "ConvertTo-VideoHorizontal run":
  test "prints usage and returns 0 for --help":
    let tmp = getTempDir() / "test_convert_to_video_horizontal_help.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["--help"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ConvertTo-VideoHorizontal")
    check content.contains("Hardware Acceleration Setup:")
    check content.contains("Performance Comparison:")
    check content.contains("Supported Hardware:")

  test "prints usage and returns 0 for -h":
    let tmp = getTempDir() / "test_convert_to_video_horizontal_h.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["-h"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 0
    check content.contains("Usage: ConvertTo-VideoHorizontal")

  test "no arguments is a missing-input-arg error":
    let tmp = getTempDir() / "test_convert_to_video_horizontal_no_args.txt"
    let f = open(tmp, fmWrite)
    let code = run(@[], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: input file")

  test "missing output arg is an error":
    let tmp = getTempDir() / "test_convert_to_video_horizontal_no_output.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["input.mp4"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Missing required argument: output file")

  test "a third positional argument is 'Too many arguments'":
    let tmp = getTempDir() / "test_convert_to_video_horizontal_too_many.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["input.mp4", "output.mp4", "extra.mp4"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Too many arguments")

  test "nonexistent input file is an error, checked before any ffmpeg invocation":
    let tmp = getTempDir() / "test_convert_to_video_horizontal_no_input.txt"
    let f = open(tmp, fmWrite)
    let code = run(@["/nonexistent/path/xyz.mp4", "/tmp/out.mp4"], f, f)
    f.close()
    let content = readFile(tmp)
    removeFile(tmp)
    check code == 1
    check content.contains("Input file '/nonexistent/path/xyz.mp4' does not exist")

  test "missing ffmpeg is exit 2 with a Missing commands error":
    # checkDeps(["ffmpeg"]) runs before fileExists(input), so no real input
    # file is needed to reach it.
    let dir = getTempDir() / "deps_convert_to_video_horizontal"
    removeDir(dir)
    createDir(dir)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@["in.mp4", "out.mp4"], f, f)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 2
    check content.contains("Missing commands: ffmpeg")

  test "characterization: all probes fail, software fallback runs last":
    let dir = getTempDir() / "char_convert_video"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    let input = dir / "in.mp4"
    writeFile(input, "")
    let output = dir / "out.mp4"
    # Every hardware probe fails (exit 1); the software fallback is the
    # fourth and final invocation and succeeds.
    writeFakeExe(dir, "ffmpeg", """
echo "$@" >> """ & log.quoteShell & """

count=$(wc -l < """ & log.quoteShell & """)
if [ "$count" -lt 4 ]; then exit 1; fi
exit 0
""")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[input, output], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check calls.len == 4
    check calls[0].contains("-hwaccel qsv")
    check calls[0].contains("h264_qsv")
    check calls[1].contains("h264_nvenc")
    check calls[2].contains("-hwaccel vaapi")
    check calls[3].contains("libx264")
    check calls[3].contains("-crf 23")
    check content.contains("All hardware acceleration methods failed")
    check content.contains("Video flip complete")

  test "characterization: a succeeding first probe skips the rest":
    let dir = getTempDir() / "char_convert_video_qsv"
    removeDir(dir)
    createDir(dir)
    let log = dir / "calls.log"
    let input = dir / "in.mp4"
    writeFile(input, "")
    let output = dir / "out.mp4"
    writeFakeExe(dir, "ffmpeg", "echo \"$@\" >> " & log.quoteShell & "\nexit 0")
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    var code: int
    withPath(dir):
      code = run(@[input, output], f, f)
    f.close()
    let calls = readFile(log).strip().splitLines()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check calls.len == 1
    check content.contains("Intel QSV/VPL hardware acceleration successful!")

  test "contract: a succeeding QSV probe makes exactly one ffmpeg call":
    let dir = getTempDir() / "contract_convert_video"
    removeDir(dir)
    createDir(dir)
    let input = dir / "in.mp4"
    writeFile(input, "")
    let output = dir / "out.mp4"
    let rec = newRecordingRunner(exitCode = 0)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[input, output], f, f, rec.runner)
    f.close()
    removeDir(dir)
    check code == 0
    check rec.calls.len == 1
    check rec.calls[0].cmd == "ffmpeg"
    check rec.calls[0].kind == "capture"
    # Exact argv, read verbatim from ConvertToVideoHorizontal.nim's first
    # tryFfmpeg call -- the characterization test above pins probe identity
    # by substring (its job is distinguishing probes by codec token); this
    # contract test pins the full construction instead.
    check rec.calls[0].args == @[
      "-y", "-hwaccel", "qsv", "-hwaccel_output_format", "qsv",
      "-c:v", "h264_qsv", "-i", input,
      "-vf", "vpp_qsv=transpose=hflip",
      "-c:v", "h264_qsv", "-preset", "fast",
      "-c:a", "aac", "-b:a", "128k", output
    ]

  test "contract: a failing software fallback still returns 0 (faithful zsh quirk)":
    # The zsh original has no `return` inside the if/elif/else chain, so it
    # always falls through to "Video flip complete" and reports success even
    # when the software fallback itself failed. This pins that quirk against
    # regression: with every ffmpeg invocation failing (exitCode 1), all
    # four probes/fallback still run and `run` still returns 0.
    let dir = getTempDir() / "contract_convert_video_all_fail"
    removeDir(dir)
    createDir(dir)
    let input = dir / "in.mp4"
    writeFile(input, "")
    let output = dir / "out.mp4"
    let rec = newRecordingRunner(exitCode = 1)
    let outPath = dir / "out.txt"
    let f = open(outPath, fmWrite)
    let code = run(@[input, output], f, f, rec.runner)
    f.close()
    let content = readFile(outPath)
    removeDir(dir)
    check code == 0
    check rec.calls.len == 4
    check content.contains("All hardware acceleration methods failed")
    check content.contains("Video flip complete")
