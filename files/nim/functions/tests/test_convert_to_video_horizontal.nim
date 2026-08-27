import std/[unittest, os, strutils]
import "../ConvertToVideoHorizontal"

# `ffmpeg` is genuinely present on this sandbox's $PATH, so the
# checkDeps-failure path (return 2) isn't constructible here without
# artificially hiding a real binary -- consistent with how
# test_update_dev_environment.nim treats the same situation for
# direnv/nix. That branch is left untested per the task brief's guidance.
# The hardware-acceleration fallback chain and the software-fallback
# ffmpeg invocation itself are NOT exercised here either: they require
# real video files and hardware-dependent codecs, and are covered by
# manual/production use only, consistent with the conventions doc's
# accepted gap for un-mockable subprocess passthrough.

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
