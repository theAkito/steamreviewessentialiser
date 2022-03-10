##[
  Extract most used keywords from reviews and generate Tag Clouds from them.
]##

import
  meta,
  word,
  database,
  configurator,
  reviewer,
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
func toTagCloud(mostUsed: OrderedTable[string, int]): TagCloud = TagCloud(tagsToPop: mostUsed)

proc loadAllReviews(appid: string): seq[SteamReviewItemRes] =
  for review in appid.loadAllReviews:
    result.add review

proc loadMostUsed(appid: string): OrderedTable[string, int] =
  appid.loadAllReviews.extractReviews.extractMostUsed(config.maxTags)

proc loadMostUsedRoots(appid: string): OrderedTable[string, int] =
  appid.loadAllReviews.extractReviews.extractMostUsedRoots(config.maxTags)

proc loadTagCloud*(appid: string, forceFresh: bool): TagCloud =
  let fresh = forceFresh or not appid.cltExists
  if fresh: result.reviewAmount = SteamContext(appId: appid).saveReviewsAll()
  result = appid.loadMostUsedRoots.toTagCloud
  result.config = loadDatabaseConfig(appid)
  result.timestampLatest = "TODO"