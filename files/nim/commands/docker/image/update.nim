import std/[os, strutils]
import "../../../lib/output"
import "../../../lib/process"
import "../../../lib/spec"
import "../../../lib/validation"

let cmdSpec* = CommandSpec(
  specVersion: specVersionCurrent,
  path: @["docker", "image", "update"],
  kind: ckVerb,
  summary: "pull Docker images to their latest versions",
  usage: "ax docker image update [image...]",
  args: @[
    ArgSpec(name: "image", required: false, variadic: true,
            description: "image names (repo:tag); default: all installed images")
  ],
  deps: @["docker"],
  dryRun: false
)

proc filterImages*(lines: seq[string]): seq[string] =
  ## Mirrors the zsh original's `sed '/^vsc/d; /^axler8r/d; /<none>/d;
  ## /devcontainer/d'`: the first two rules are anchored-prefix matches, the
  ## last two are unanchored substring matches. Blank lines are dropped too
  ## (mirrors splitting `docker image list` output on newlines).
  result = @[]
  for line in lines:
    if line.len == 0: continue
    if line.startsWith("vsc"): continue
    if line.startsWith("axler8r"): continue
    if line.contains("<none>"): continue
    if line.contains("devcontainer"): continue
    result.add(line)

proc run*(
  args: seq[string],
  outp: File = stdout,
  errp: File = stderr,
  runner: Runner = defaultRunner
): int =
  if args.len > 0 and (args[0] == "-h" or args[0] == "--help"):
    outp.writeLine """Usage: ax docker image update [image...]

Pull Docker images to their latest versions. With no arguments, updates all
installed images (excluding devcontainer, vsc, and local axler8r images).

Options:
    -h, --help    Show this help message

Arguments:
    image         One or more image names (repo:tag)

Examples:
    ax docker image update
    ax docker image update nginx:latest postgres:16
    ax docker image list -o json | jq -r '.[] | .repository + ":" + .tag' | xargs ax docker image update"""
    return 0

  if not checkDeps(["docker"], errp): return 2

  var images: seq[string]

  if args.len > 0:
    images = args
  else:
    let listing = runner.capture(
      "docker",
      @["image", "list", "--format={{.Repository}}:{{.Tag}}"]
    ).output
    images = filterImages(listing.splitLines())

  if images.len == 0:
    info("No images to update.", errp)
    return 0

  # Sequential, one `docker pull` per image, matching `xargs -L1`'s default
  # non-parallel behaviour. Each pull inherits the real stdout/stderr so
  # progress streams live, matching the zsh original's passthrough. The zsh
  # original doesn't check exit codes (no `-x`, no `|| return` in the loop),
  # so a failed pull doesn't abort the remaining ones; we track failures only
  # to fold into our own exit code, which the original left unspecified.
  var anyFailed = false
  for image in images:
    let code = runner.runInherited("docker", @["pull", image])
    if code != 0:
      anyFailed = true

  outp.write("\n")

  result = if anyFailed: 1 else: 0

when isMainModule:
  axMain(cmdSpec):
    run(commandLineParams())
