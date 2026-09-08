## The verb lexicon, embedded at compile time from files/nim/lexicon.json.
## The same file is read by flake.nix at eval time (leaf validation before
## anything builds) and quoted in docs/ax-cli-design.md; this module gives
## the driver and `ax self build-registry` the runtime view: canonical
## verbs, blessed aliases, and the enumerated report-noun exceptions.
import std/[json, tables]

type VerbDef* = object
  name*: string
  aliases*: seq[string]
  meaning*: string

const lexiconRaw = staticRead("../lexicon.json")

proc parseLexicon(): tuple[verbs: seq[VerbDef], reportNouns: seq[string]] =
  let node = parseJson(lexiconRaw)
  for v in node["verbs"]:
    var d = VerbDef(name: v["name"].getStr, meaning: v["meaning"].getStr)
    for a in v["aliases"]:
      d.aliases.add a.getStr
    result.verbs.add d
  for n in node["reportNouns"]:
    result.reportNouns.add n.getStr

let parsed = parseLexicon()

let verbs*: seq[VerbDef] = parsed.verbs
let reportNouns*: seq[string] = parsed.reportNouns

let aliasTable*: Table[string, string] = block:
  var t: Table[string, string]
  for v in verbs:
    for a in v.aliases:
      t[a] = v.name
  t

proc canonicalLeaf*(word: string): string =
  ## Resolves a blessed alias (ls, rm, new, info, umount) to its canonical
  ## verb; any other word passes through unchanged.
  aliasTable.getOrDefault(word, word)

proc isAllowedLeaf*(word: string): bool =
  ## True when `word` is a canonical verb or an enumerated report-noun.
  ## Aliases are NOT allowed leaves: the registry stores canonical names
  ## only, and the driver resolves aliases before matching.
  for v in verbs:
    if v.name == word:
      return true
  word in reportNouns
