import std/os
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["media", "video", "convert"],
  kind: ckVerb,
  summary: "transform a video file (currently: horizontal flip)",
  usage: "ax media video convert <input> <output> --orientation horizontal",
  args: @[
    ArgSpec(name: "input", required: true,
            description: "the video file to read"),
    ArgSpec(name: "output", required: true,
            description: "the video file to write")
  ],
  flags: @[
    FlagSpec(long: "orientation", takesValue: true,
             description: "the transform to apply; only 'horizontal' is supported")
  ],
  deps: @["ffmpeg"],
  dryRun: false
)

proc tryFfmpeg(runner: Runner, ffmpegArgs: seq[string]): bool =
  ## One hardware-acceleration probe. Output is drained and discarded --
  ## only the exit code matters, matching the zsh original's 2>/dev/null.
  runner.runQuiet("ffmpeg", ffmpegArgs) == 0

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax media video convert <input> <output> --orientation horizontal

Description:
    Flips a video horizontally and re-encodes the audio to prevent timestamp
    sync issues. Attempts hardware acceleration first, then falls back to
    software processing if hardware is not available. The --orientation flag
    names the transform so future codecs/transforms extend this command
    rather than adding new ones.

Options:
    -h, --help                Show this help message
    --orientation horizontal  The transform to apply (required; only
                              'horizontal' is supported today)

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
    ax media video convert input.mp4 output.mp4 --orientation horizontal"""
    return 0

  var input = ""
  var output = ""
  var orientation = ""
  var i = 0
  while i < args.len:
    let a = args[i]
    if a == "--orientation":
      if i + 1 >= args.len:
        error("Missing value for --orientation", errp)
        return 64
      orientation = args[i + 1]
      i += 2
    elif a.len > 0 and a[0] == '-':
      error("Unknown option: " & a, errp)
      return 64
    elif input.len == 0:
      input = a
      inc i
    elif output.len == 0:
      output = a
      inc i
    else:
      error("Too many arguments", errp)
      return 64

  if not requireArg(input, "input file", errp): return 64
  if not requireArg(output, "output file", errp): return 64
  if not requireArg(orientation, "--orientation", errp): return 64
  if orientation != "horizontal":
    error("Unsupported orientation: " & orientation &
          " (supported: horizontal)", errp)
    return 64
  if not checkDeps(["ffmpeg"], errp): return 2

  if not fileExists(input):
    error("Input file '" & input & "' does not exist", errp)
    return 1

  outp.writeLine("Input file: " & input)
  outp.writeLine("Output file: " & output)
  outp.writeLine("Attempting hardware-accelerated flip...")

  if tryFfmpeg(runner, @[
    "-y", "-hwaccel", "qsv", "-hwaccel_output_format", "qsv",
    "-c:v", "h264_qsv", "-i", input,
    "-vf", "vpp_qsv=transpose=hflip",
    "-c:v", "h264_qsv", "-preset", "fast",
    "-c:a", "aac", "-b:a", "128k", output
  ]):
    outp.writeLine("Intel QSV/VPL hardware acceleration successful!")
  elif tryFfmpeg(runner, @[
    "-y", "-i", input, "-vf", "hflip",
    "-c:v", "h264_nvenc", "-preset", "fast",
    "-c:a", "aac", "-b:a", "128k", output
  ]):
    outp.writeLine("NVIDIA NVENC hardware acceleration successful!")
  elif tryFfmpeg(runner, @[
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
    # Software fallback: real stdout/stderr reach the terminal live,
    # matching the original's unsuppressed passthrough.
    discard runner.runInherited("ffmpeg", @[
      "-y", "-i", input, "-vf", "hflip",
      "-c:v", "libx264", "-preset", "fast", "-crf", "23",
      "-c:a", "aac", "-b:a", "128k", output
    ])

  # Unconditional, even if the software fallback above failed: the zsh
  # original has no `return` inside the if/elif/else chain, so it always
  # falls through to this line and the function (and thus the script,
  # since there's no final `return` after the call either) always reports
  # success. Preserved faithfully rather than "fixed" -- see task brief.
  outp.writeLine("Video flip complete: " & output)
  return 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
