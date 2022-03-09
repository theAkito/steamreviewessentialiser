##[
  Spell checker & auto-corrector.
  Currently, only deals with text written in American English.
]##

const header = when isMainModule: "externlib/hunspell/src/hunspell/hunspell.h" else: "steamreviewessentialiser/externlib/hunspell/src/hunspell/hunspell.h"

type
  Hunhandle {.header: header, importc: "Hunhandle".} = object

# Import C
proc newHunspell(affpath: cstring, dpath: cstring): ptr Hunhandle {.header: header, importc: "Hunspell_create".}
proc addDic(hunspell: ptr Hunhandle, dpath: cstring): cint {.header: header, importc: "Hunspell_add_dic".}
proc spell(hunspell: ptr Hunhandle, word: cstring): bool {.header: header, importc: "Hunspell_spell".}
proc suggest(hunspell: ptr Hunhandle, resultArray: ptr cstringArray, word: cstring): cint {.header: header, importc: "Hunspell_suggest".}
proc analyze(hunspell: ptr Hunhandle, resultArray: ptr cstringArray, word: cstring): cint {.header: header, importc: "Hunspell_analyze".}
proc stem(hunspell: ptr Hunhandle, suggestions: ptr cstringArray, morph: cstringArray, n: cint): cint {.header: header, importc: "Hunspell_stem2".}

const
  pathDictBase = "src/steamreviewessentialiser/externlib/dictionaries/"
  pathAff_EN_US: cstring = pathDictBase & "en_US.aff"  ## Path to AFF file.
  pathDict_EN_US: cstring = pathDictBase & "en_US.dic" ## Path to DIC file.
var
  hunspell: ptr Hunhandle = newHunspell(pathAffEN_US, pathDictEN_US) ## Hunspell instance.

proc spell*(word: string): bool = hunspell.spell(word.cstring)
proc suggest*(word: string): seq[string] =
  var resultSuggest: cstringArray
  let resultSuggestLen = hunspell.suggest(resultSuggest.addr, word.cstring)
  result = resultSuggest.cstringArrayToSeq(resultSuggestLen)
proc stem*(word: string): string = # Sequence is empty and then excepts, due to index error, when stem cannot be detected.
  try:
    var
      resultStem: cstringArray
      resultMorph: cstringArray
    var resultMorphLen = hunspell.analyze(resultMorph.addr, word.cstring)
    if resultMorphLen > 0: 
      let stemsAmountFound = hunspell.stem(resultStem.addr, resultMorph, resultMorphLen)
      result = if stemsAmountFound > 0: $resultStem[0] else: word
    else:
      return word
  except:
    result = word

proc root*(word: string): string =
  ## Get most likely correct version of word.
  ## Then extract word stem.
  if spell(word): return word.stem
  let correct = try: word.suggest()[0] except: return word.stem
  correct.stem

when isMainModule:
  import json
  var resultArray: cstringArray
  echo "Spelling of \"Recommendation\" is correct: " & $hunspell.spell("Recommendation".cstring)
  echo "Spelling of \"Recommnedation\" is correct: " & $hunspell.spell("Recommnedation".cstring)
  echo()
  echo hunspell.suggest(resultArray.addr, "Recommendation".cstring)
  echo "Suggestions for \"Recommendation\":\n" & pretty(% $resultArray[0])
  echo()
  resultArray = nil
  echo hunspell.suggest(resultArray.addr, "hell".cstring)
  echo "Suggestions for \"hell\":\n" & pretty(% $resultArray[0])
  echo()
  resultArray = nil
  var resultMorph: cstringArray
  var n = hunspell.analyze(resultMorph.addr, "Mixing".cstring)
  echo "Analysis for \"Mixing\":\n" & pretty(% $resultMorph[0])
  echo()
  resultArray = nil
  echo hunspell.stem(resultArray.addr, resultMorph, n)
  echo "Stem from morphological analysis for \"Mixing\":\n" & pretty(% $resultArray[0])