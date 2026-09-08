#!/usr/bin/env bash
# Run from files/nim. Only newly-created temporary paths are modified.
set -euo pipefail
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
unset AX_OUTPUT AX_DRY_RUN AX_COLOR AX_QUIET AX_VERBOSE
mkdir -p "$root/bin" "$root/libexec/ax" "$root/share/ax"
if [[ -n "${AX_DRIVER:-}" ]]; then
  install -m755 "$AX_DRIVER" "$root/bin/ax"
else
  nim c -d:release --parallelBuild:"${NIX_BUILD_CORES:-2}" \
    --nimcache:"$root/cache" -o:"$root/bin/ax" ax.nim
fi
nim c -d:release --parallelBuild:"${NIX_BUILD_CORES:-2}" \
  --nimcache:"$root/cache" -o:"$root/libexec/ax/ax-test-get" tests/fixtures/echo.nim
ax="$root/bin/ax"
"$ax" self build-registry > "$root/share/ax/registry.json"
printf '{"test":"integration fixtures"}\n' > "$root/share/ax/groups.json"

expect_exit() {
  local expected=$1 code=0
  shift
  "$@" > "$root/out" 2> "$root/err" || code=$?
  [[ $code == "$expected" ]] || {
    printf 'Expected exit %s, got %s: %s\n' "$expected" "$code" "$*" >&2
    cat "$root/err" >&2
    exit 1
  }
}

AX_OUTPUT=table "$ax" -q --color never test get -o json -- 'two words' '-n' '--help' > "$root/out"
jq -e '.args == ["--", "two words", "-n", "--help"] and .output == "json"
       and .color == "never" and .quiet == "1"' "$root/out" > /dev/null
expect_exit 7 "$ax" test get --fail
expect_exit 1 "$ax" test get --throw
grep -q 'fixture exception' "$root/err"
[[ ! -s "$root/out" ]]
expect_exit 64 "$ax" test get --unknown
expect_exit 64 "$ax" -n test get
expect_exit 0 env AX_DRY_RUN=1 "$ax" test get --help
expect_exit 0 env AX_DRY_RUN=1 "$root/libexec/ax/ax-test-get" --help

mkdir -p "$root/work/files/nim/commands"
printf '{}\n' > "$root/work/files/nim/commands/groups.json"
pushd "$root/work" > /dev/null
expect_exit 0 "$ax" self new-command example create --help
expect_exit 64 "$ax" -n self new-command example create
expect_exit 64 env AX_DRY_RUN=1 "$ax" self new-command example create
[[ ! -e files/nim/commands/example ]]
expect_exit 0 "$ax" --quiet self doctor
[[ ! -s "$root/err" && ! -s "$root/out" ]]
popd > /dev/null
printf 'Executable integration checks passed\n'
