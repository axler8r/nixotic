import std/[sequtils, unittest]
import "../lexicon"

suite "lexicon":
  test "verbs and report-nouns load from the embedded lexicon.json":
    check verbs.anyIt(it.name == "list")
    check verbs.anyIt(it.name == "mount")
    check "swap" in reportNouns
    check "templates" in reportNouns

  test "canonicalLeaf resolves every blessed alias":
    check canonicalLeaf("ls") == "list"
    check canonicalLeaf("rm") == "remove"
    check canonicalLeaf("new") == "create"
    check canonicalLeaf("info") == "show"
    check canonicalLeaf("umount") == "unmount"

  test "canonicalLeaf passes non-aliases through unchanged":
    check canonicalLeaf("mount") == "mount"
    check canonicalLeaf("frobnicate") == "frobnicate"

  test "isAllowedLeaf accepts canonical verbs and report-nouns only":
    check isAllowedLeaf("list")
    check isAllowedLeaf("swap")
    # Aliases are not allowed leaves: the registry stores canonical names.
    check not isAllowedLeaf("ls")
    check not isAllowedLeaf("frobnicate")
