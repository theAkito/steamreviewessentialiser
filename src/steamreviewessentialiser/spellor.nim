##[
  Spell checker & auto-corrector.
]##

# https://forum.nim-lang.org/t/6833#42762

import
  meta,
  model/[
    tag
  ],
  std/[
    os,
    json,
    logging,
    strutils
  ],
  pkg/[
    cppstl
  ]

const header = "externlib/hunspell/src/hunspell/hunspell.hxx"

type
  HunspellObj {.header: header, importcpp: "Hunspell".} = object

# Import C++
proc newHunspell(affpath: cstring, dpath: cstring): ptr HunspellObj {.importcpp: "new Hunspell(@)".}
proc addDic(hunspell: ptr HunspellObj, dpath: cstring): cint {.header: header, importcpp: "#.add_dic(@)".}
proc spell(hunspell: ptr HunspellObj, word: cstring): bool {.header: header, importcpp: "#.spell(@)".}
proc spell(hunspell: ptr HunspellObj, word: cstring, info: cint, root: cstring): bool {.header: header, importcpp: "#.spell(@)".}
proc suggest(hunspell: ptr HunspellObj, word: cstring): CppVector[CppString] {.header: header, importcpp: "#.suggest(@)".}
# C++ Support Utilities
func high(v: CppVector): uint = v.len - 1
func toSeq(v: CppVector[CppString]): seq[string] =
  for word in v: result.add word.toString

const
  pathDictBase = "src/steamreviewessentialiser/externlib/dictionaries/"
  pathAff_EN_US: cstring = pathDictBase & "en_US.aff"  ## Path to AFF file.
  pathDict_EN_US: cstring = pathDictBase & "en_US.dic" ## Path to DIC file.
var
  hunspell: ptr HunspellObj = newHunspell(pathAffEN_US, pathDictEN_US) ## Hunspell instance.

when isMainModule:
  echo "Spelling of \"Recommendation\" is correct: " & $hunspell.spell("Recommendation".cstring)
  echo "Spelling of \"Recommnedation\" is correct: " & $hunspell.spell("Recommnedation".cstring)
  echo()
  echo "Suggestions for \"Recommendation\":\n" & pretty(% hunspell.suggest("Recommendation".cstring).toSeq)
  echo()
  echo "Suggestions for \"hell\":\n" & pretty(% hunspell.suggest("hell".cstring).toSeq)