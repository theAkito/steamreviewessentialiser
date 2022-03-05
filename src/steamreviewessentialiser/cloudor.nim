##[
  Extract most used keywords from reviews and generate Tag Clouds from them.
]##

import
  meta,
  word,
  database,
  configurator,
  model/[
    steam,
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

func extractReviews(reviews: seq[SteamReviewItemRes]): seq[string] = reviews.mapIt(it.review)
func toTagCloud(mostUsed: OrderedTable[string, int]): TagCloud =
  result =
    TagCloud(
      tagsPop: initOrderedSet[string]()
    )
  for word in mostUsed.keys:
    result.tagsPop.incl word

proc loadAllReviews(appid: string): seq[SteamReviewItemRes] =
  for review in appid.loadAllReviews:
    result.add review

proc loadMostUsed(appid: string): OrderedTable[string, int] =
  appid.loadAllReviews.extractReviews.extractMostUsed(config.maxItems)

proc loadMostUsedRoots(appid: string): OrderedTable[string, int] =
  appid.loadAllReviews.extractReviews.extractMostUsedRoots(config.maxItems)

proc loadTagCloud*(appid: string): TagCloud = appid.loadMostUsedRoots.toTagCloud