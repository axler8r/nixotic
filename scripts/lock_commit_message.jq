# Compare the top-level inputs of two lock files and print a commit message
# only when one or more of them changed.
def inputs_of($l): $l.nodes.root.inputs | with_entries(select(.value | type == "string"));
def node($l; $i; $k): $l.nodes[$i[$k] // ""];
def day: .locked.lastModified | todate[:10];

$old[0] as $o | $new[0] as $n | inputs_of($o) as $oi | inputs_of($n) as $ni
| [
    ($oi + $ni) | keys[] as $k
    | node($o; $oi; $k) as $a | node($n; $ni; $k) as $b
    | select(($a.locked | {rev, narHash}) != ($b.locked | {rev, narHash}))
    | {
        k: $k,
        from: (if $a == null then "added" else ($a | day) end),
        to: (if $b == null then "removed" else ($b | day) end)
      }
  ]
| select(length > 0)
| (map(.k | length) | max) as $w
| "dep(system): update flake inputs\n\nupdates:\n"
  + (map("- '\(.k)':" + " " * ($w - (.k | length) + 1) + "\(.from) -> \(.to)") | join("\n"))
