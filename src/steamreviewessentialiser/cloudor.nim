##[
  Extract most used keywords from reviews and generate Tag Clouds from them.
]##

import
  meta,
  spellor,
  model/[
    tag
  ],
  std/[
    json,
    logging,
    strutils,
    sequtils,
    tables,
    sets
  ]

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "cloudor" & logMsgSuffix)

func extractWords(text: openArray[string]): seq[string] =
  for content in text:
    for word in content.split():
      result.add word

func mapTagToPopularity(words: openArray[string], amount: int = words.len): OrderedTable[string, int] =
  var
    counter: int
    countTable = words.toCountTable
  countTable.sort
  for word, freq in countTable.pairs:
    counter.inc
    result[word] = freq
    if counter >= amount: return

func extractMostUsed*(text: openArray[string], amount: int = 15): OrderedTable[string, int] =
  text.extractWords.mapTagToPopularity(amount)

proc extractMostUsedRoots*(text: openArray[string], amount: int = 15): OrderedTable[string, int] =
  for word, freq in text.extractMostUsed(amount).pairs:
    result[word.root] = freq
  logger.log(lvlDebug, "[extractMostUsedRoots] Result: " & pretty(%* result))

when isMainModule:
  # import tables, sets, sequtils
  const testReviewContent = ["mostused aint what for lobby", "lobby why mostused", "mostused aint what"]
  var
    words: seq[string]
    tagsPop: OrderedSet[string]
    tagToPop: JsonNode = newJObject()
    countTable: CountTable[string]
  for content in testReviewContent:
    for word in content.split():
      words.add word
  countTable = words.toCountTable
  echo "Word used most: " & pretty(%* countTable.largest.key) & "\n"
  countTable.sort
  for pair in countTable.pairs:
    tagsPop.incl pair[0]
    tagToPop[pair[0]] = % pair[1]
  echo "Words ordered by popularity: " & pretty(%* tagsPop.toSeq) & "\n"
  echo "Whole CountTable, where the most used word is on top mapped to how often it was used: " & tagToPop.pretty