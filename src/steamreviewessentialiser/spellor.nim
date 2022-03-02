##[
  Spell checker & auto-corrector.
]##

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
  ]

type
  HunspellObj {.header: "externlib/hunspell/src/hunspell/hunspell.hxx", importcpp: "Hunspell".} = object

# Import C++
proc newHunspell(affpath: cstring, dpath: cstring): ptr HunspellObj {.importcpp: "new Hunspell(@)".}
proc add_dic(hunspell: ptr HunspellObj, dpath: cstring): cint {.header: "externlib/hunspell/src/hunspell/hunspell.hxx", importcpp: "#.add_dic(@)".}
proc spell(hunspell: ptr HunspellObj, word: cstring): bool {.header: "externlib/hunspell/src/hunspell/hunspell.hxx", importcpp: "#.spell(@)".}
proc spell(hunspell: ptr HunspellObj, word: cstring, info: cint, root: cstring): bool {.header: "externlib/hunspell/src/hunspell/hunspell.hxx", importcpp: "#.spell(@)".}

const
  pathAffEN_US: cstring = "src/steamreviewessentialiser/externlib/dictionaries/en_US.aff"  ## Path to AFF file.
  pathDictEN_US: cstring = "src/steamreviewessentialiser/externlib/dictionaries/en_US.dic" ## Path to DIC file.
var
  hunspell: ptr HunspellObj = newHunspell(pathAffEN_US, pathDictEN_US) ## Hunspell instance.

when isMainModule:
  echo "Spelling of \"Recommendation\" is correct: " & $hunspell.spell("Recommendation".cstring)
  echo "Spelling of \"Recommnedation\" is correct: " & $hunspell.spell("Recommnedation".cstring)