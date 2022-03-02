##[
  Extract most used keywords from reviews and generate Tag Clouds from them.
]##

import
  meta,
  model/[
    tag
  ],
  std/[
    json,
    logging,
    strutils
  ]

when isMainModule:
  import tables, sets, sequtils
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