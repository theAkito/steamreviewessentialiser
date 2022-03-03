##[
  Spell checker & auto-corrector.
  Currently, only deals with text written in American English.
]##

# https://forum.nim-lang.org/t/6833#42762

import cppstl

const header = "steamreviewessentialiser/externlib/hunspell/src/hunspell/hunspell.hxx"

type
  HunspellObj {.header: header, importcpp: "Hunspell".} = object

# Import C++
proc newHunspell(affpath: cstring, dpath: cstring): ptr HunspellObj {.importcpp: "new Hunspell(@)".}
proc addDic(hunspell: ptr HunspellObj, dpath: cstring): cint {.header: header, importcpp: "#.add_dic(@)".}
proc spell(hunspell: ptr HunspellObj, word: cstring): bool {.header: header, importcpp: "#.spell(@)".}
proc spell(hunspell: ptr HunspellObj, word: cstring, info: cint, root: cstring): bool {.header: header, importcpp: "#.spell(@)".}
proc suggest(hunspell: ptr HunspellObj, word: cstring): CppVector[CppString] {.header: header, importcpp: "#.suggest(@)".}
proc analyze(hunspell: ptr HunspellObj, word: cstring): CppVector[CppString] {.header: header, importcpp: "#.analyze(@)".}
proc stem(hunspell: ptr HunspellObj, morph: CppVector[CppString]): CppVector[CppString] {.header: header, importcpp: "#.stem(@)".}
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

proc spell*(word: string): bool = hunspell.spell(word.cstring)
proc suggest*(word: string): seq[string] = hunspell.suggest(word.cstring).toSeq
proc stem*(word: string): string = # Sequence is empty and then excepts, due to index error, when stem cannot be detected.
  try: hunspell.stem(hunspell.analyze(word.cstring)).toSeq()[0] except: word

proc root*(word: string): string =
  ## Get most likely correct version of word.
  ## Then extract word stem.
  if spell(word): return word.stem
  let correct = word.suggest()[0]
  correct.stem

when isMainModule:
  import json
  echo "Spelling of \"Recommendation\" is correct: " & $hunspell.spell("Recommendation".cstring)
  echo "Spelling of \"Recommnedation\" is correct: " & $hunspell.spell("Recommnedation".cstring)
  echo()
  echo "Suggestions for \"Recommendation\":\n" & pretty(% hunspell.suggest("Recommendation".cstring).toSeq)
  echo()
  echo "Suggestions for \"hell\":\n" & pretty(% hunspell.suggest("hell".cstring).toSeq)
  echo()
  let morph1 = hunspell.analyze("Mixing".cstring)
  echo "Analysis for \"Mixing\":\n" & pretty(% morph1.toSeq)
  echo()
  echo "Stem from morphological analysis for \"Mixing\":\n" & pretty(% hunspell.stem(morph1).toSeq)