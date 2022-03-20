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
    helper,
    steam,
    tag
  ],
  std/[
    logging,
    sequtils,
    tables
  ],
  pkg/[
    timestamp
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

proc loadTagCloud*(
  appid: string,
  forceFresh: bool,
  amountReview: int,
  amountTag: int,
  reviewType: ReviewType = dbConfig.reviewType,
  purchaseType: PurchaseType = dbConfig.purchaseType,
  language: Language = dbConfig.language
): TagCloud =
  let fresh = forceFresh or not appid.cltExists
  result = TagCloud()
  if fresh: discard SteamContext(appId: appid).saveReviewsAll(
    amountReview,
    amountTag,
    reviewType,
    purchaseType,
    language
  )
  var status = appid.loadDatabaseStatus()
  result = appid.loadMostUsedRoots.toTagCloud
  result.config = loadDatabaseConfig(appid)
  result.amountReview = status.recommendationIDs.len
  result.timestampLatest = $status.timestampLatest
  result.timestampUpdate = $status.timestampUpdate
  result.timestampComplete = $status.timestampComplete