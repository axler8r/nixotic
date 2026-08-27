import std/[os, osproc]
import "../lib/output"
import "../lib/validation"

proc tryFfmpeg(ffmpegArgs: seq[string]): bool =
  ## Runs one hardware-acceleration probe attempt: stdout/stderr are
  ## captured (not inherited, i.e. not poParentStreams) and never read --
  ## only the exit code is inspected, matching the zsh original's
  ## `2>/dev/null` (stderr suppressed) while leaving stdout un-suppressed in
  ## spirit (ffmpeg writes essentially nothing to stdout in practice; its
  ## progress/status output goes to stderr). osproc has no per-stream
  ## inherit/discard mix (see the similar note in GetHelp.nim), so this is
  ## the closest faithful approximation: neither stream reaches the
  ## terminal for these three probe attempts. Not draining the pipes is a
  ## theoretical deadlock risk if a probe wrote enough output to fill the
  ## OS pipe buffer before failing, but these three attempts fail fast on
  ## missing hardware/codecs in practice -- an accepted limitation, same
  ## shape as other un-mockable subprocess passthrough gaps in this codebase.
  var p = startProcess("ffmpeg", args = ffmpegArgs, options = {poUsePath})
  result = p.waitForExit() == 0
  p.close()

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ConvertTo-VideoHorizontal <input> <output>

Description:
    Flips a video horizontally and re-encodes the audio to prevent timestamp
    sync issues. Attempts hardware acceleration first, then falls back to
    software processing if hardware is not available.

Options:
    -h, --help  Show this help message

Hardware Acceleration Setup:
    For Intel QSV (Quick Sync Video) - RECOMMENDED for Intel CPUs:
        sudo apt install vainfo intel-media-va-driver-non-free libva-dev libmfx-dev

    For NVIDIA NVENC (if you have an NVIDIA GPU):
        sudo apt install libnvidia-encode-535 (or current driver version)

    Test hardware support after installation:
        vainfo                          # Check Intel VA-API support
        ffmpeg -encoders | grep qsv     # Check Intel QSV encoders
        ffmpeg -encoders | grep nvenc   # Check NVIDIA NVENC encoders

Performance Comparison:
    - Software encoding: ~1-2x real-time
    - Intel QSV: ~5-8x real-time
    - NVIDIA NVENC: ~4-10x real-time

Supported Hardware:
    - Intel: 6th gen Core (Skylake) and newer with integrated graphics
    - NVIDIA: GTX 1050/1060 and newer, RTX series, Quadro P series

Examples:
    ConvertTo-VideoHorizontal input.mp4 output.mp4"""
    return 0

  # Positional arg parsing, no flags beyond -h/--help: first arg -> input,
  # second -> output, a third is an error. Mirrors the zsh original's
  # `case "$1" in *) ... ;; esac` loop, which is really just this in
  # disguise -- every arg falls into the catch-all branch.
  var input = ""
  var output = ""
  for a in args:
    if input.len == 0:
      input = a
    elif output.len == 0:
      output = a
    else:
      error("Too many arguments", errp)
      return 1

  if not requireArg(input, "input file", errp): return 1
  if not requireArg(output, "output file", errp): return 1
  if not checkDeps(["ffmpeg"], errp): return 2

  if not fileExists(input):
    error("Input file '" & input & "' does not exist", errp)
    return 1

  outp.writeLine("Input file: " & input)
  outp.writeLine("Output file: " & output)
  outp.writeLine("Attempting hardware-accelerated flip...")

  if tryFfmpeg(@[
    "-y", "-hwaccel", "qsv", "-hwaccel_output_format", "qsv",
    "-c:v", "h264_qsv", "-i", input,
    "-vf", "vpp_qsv=transpose=hflip",
    "-c:v", "h264_qsv", "-preset", "fast",
    "-c:a", "aac", "-b:a", "128k", output
  ]):
    outp.writeLine("Intel QSV/VPL hardware acceleration successful!")
  elif tryFfmpeg(@[
    "-y", "-i", input, "-vf", "hflip",
    "-c:v", "h264_nvenc", "-preset", "fast",
    "-c:a", "aac", "-b:a", "128k", output
  ]):
    outp.writeLine("NVIDIA NVENC hardware acceleration successful!")
  elif tryFfmpeg(@[
    "-y", "-hwaccel", "vaapi", "-hwaccel_output_format", "vaapi",
    "-hwaccel_device", "/dev/dri/renderD128",
    "-i", input,
    "-vf", "scale_vaapi=w=-2:h=-2,hwdownload,format=nv12,hwupload,scale_vaapi=w=iw:h=ih:format=nv12",
    "-c:v", "h264_vaapi",
    "-c:a", "aac", "-b:a", "128k", output
  ]):
    outp.writeLine("VA-API hardware acceleration successful!")
  else:
    outp.writeLine("All hardware acceleration methods failed, falling back to software processing...")
    # Software fallback: real stdout/stderr reach the terminal live
    # (poParentStreams), matching the original's unsuppressed passthrough.
    var p = startProcess("ffmpeg", args = @[
      "-y", "-i", input, "-vf", "hflip",
      "-c:v", "libx264", "-preset", "fast", "-crf", "23",
      "-c:a", "aac", "-b:a", "128k", output
    ], options = {poUsePath, poParentStreams})
    discard p.waitForExit()
    p.close()

  # Unconditional, even if the software fallback above failed: the zsh
  # original has no `return` inside the if/elif/else chain, so it always
  # falls through to this line and the function (and thus the script,
  # since there's no final `return` after the call either) always reports
  # success. Preserved faithfully rather than "fixed" -- see task brief.
  outp.writeLine("Video flip complete: " & output)
  return 0

when isMainModule:
  quit(run(commandLineParams()))
