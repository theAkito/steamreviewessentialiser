import
  meta,
  apiutils,
  database,
  configurator,
  model/[
    helper,
    steam
  ],
  std/[
    logging,
    sequtils,
    strutils,
    strformat,
    options,
    json,
    math,
    sets,
    os,
    with
  ],
  pkg/[
    puppy,
    nimdbx,
    timestamp
  ]

import model/database as modeldb

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "reviewer" & logMsgSuffix)

func genBatchAmountBonus(total, batchSize: int): int =
  if total mod batchSize == 0: 0 else: 1

func genBatchAmount(total, batchSize: int): int = floor(total / batchSize).toInt() + genBatchAmountBonus(total, batchSize)

proc genBatchIterLimit(reviewsTotal, batchSize: int, amountReview: int): int =
  let
    reviewsTotalBatches = genBatchAmount(reviewsTotal, batchSize)
    maxBatches = genBatchAmount(amountReview, batchSize)
  if reviewsTotalBatches < maxBatches:
    reviewsTotalBatches
  else:
    maxBatches

func genRequestUrl(query: SteamReviewQuery, fresh = false #[ Set to `true` on first request!]#): Url =
  ## Do not encode `query.cursor` manually! cURL encodes already!
  ## API Reference: https://partner.steamgames.com/doc/store/getreviews
  let
    queryFilter = query.filter
    defaultQueries = @[
      ("json", "1"),
      ("appid", query.appid),
      ("cursor", query.cursor),
      ("num_per_page", query.num_per_page),
      ("filter", queryFilter),
      ("language", query.language),
      ("review_type", query.review_type),
      ("purchase_type", query.purchase_type)
    ]
    queryDayRangePartial = query.day_range.get("")
    optionalQueries = try:
      if queryFilter == "all" and not queryDayRangePartial.isEmptyOrWhitespace:
        @[("day_range", queryDayRangePartial)] else: @[]
    except: @[]
    queries = if fresh:
        defaultQueries &
        optionalQueries
      else: defaultQueries
  Url(
    scheme: "https",
    hostname: "store.steampowered.com",
    path: "/appreviews/" & query.appid,
    query: queries
  )

func extractReviews(batch: SteamReviewsRes): seq[SteamReviewItemRes] = batch.reviews.get(@[])

proc genRequest(ctx: SteamContext, fresh = false #[ Set to `true` on first request!]#): Request =
  let
    query = SteamReviewQuery(
      ## API Reference: https://partner.steamgames.com/doc/store/getreviews
      #TODO: Make these configurable through app's configuration JSON file.
      appid: ctx.appId,
      filter: "updated",
      language: "all",
      day_range: none(string),
      cursor: ctx.cursor,
      review_type: "all",
      purchase_type: "steam",
      num_per_page: "100"
    )
  Request(
    url: genRequestUrl(query, fresh),
    verb: "get",
    headers: @[headerJson]
  )

proc retrieveReviewBatch(ctx: SteamContext, fresh = false #[ Set to `true` on first request!]#): SteamReviewsRes =
  let
    req = genRequest(ctx, fresh)
    resp = req.fetch()
    jResp =
      try: resp.body.parseJson()
      except: raise SteamDefect.newException(exceptMsgMsgPostErrorParse)
  try:
    jResp.to(SteamReviewsRes)
  except:
    logger.log(lvlFatal, "Failed to parse Steam Review batch:\n" & jResp{"query_summary"}.pretty)
    raise getCurrentException()

iterator retrieveReviewsAll(ctx: SteamContext, cursorProvided = "*", amountReview: int): SteamReviewsRes {.inline.} =
  var
    count: int = 0
    cursorPrevious = "*"
  ctx.cursor = cursorPrevious
  let
    batchFirst = ctx.retrieveReviewBatch(true)
  #TODO: Does this work if new reviews were added in the meantime? The cursors might've changed.
  cursorPrevious = if cursorProvided == cursorPrevious: batchFirst.cursor else: cursorProvided
  let
    reviewsTotal = try:
        batchFirst.query_summary.get().total_reviews.get()
      except:
        logger.log(lvlFatal, "Failed to retrieve total amount of Steam Reviews:\n" & pretty(%* batchFirst))
        raise getCurrentException()
    reviewsPerBatch = try:
        batchFirst.query_summary.get().num_reviews.get()
      except:
        logger.log(lvlFatal, "Failed to retrieve current batch's amount of Steam Reviews:\n" & pretty(%* batchFirst))
        raise getCurrentException()
    limit = genBatchIterLimit(reviewsTotal, reviewsPerBatch, amountReview)
  for i in 1..limit:
    ctx.cursor = cursorPrevious
    let
      fresh = i == 1
      batch = ctx.retrieveReviewBatch(fresh)
    try: logger.log(lvlDebug, "Actual number of reviews retrieved in this batch: " & $batch.query_summary.get().num_reviews.get())
    except: discard
    count.inc
    yield batch
    cursorPrevious = batch.cursor
    if count < limit: sleep config.intervalAPI

proc saveReviewsAllBase(ctx: SteamContext, ct: CollectionTransaction, amountReview: int): DatabaseStatus {.raises: [Exception #[Due to Lumberjack.]#].} =
  ##[
    Requires an open CollectionTransaction.
  ]##
  template finishResult() =
    result.recommendationIDs.add orderedRecommendationIDs.toSeq
    result.timestampLatest = timestampLatest.steamTimestampToTimestamp
  var
    counter: int = 0
    counterDup: int
    orderedRecommendationIDs = initOrderedSet[string](amountReview)
    timestampLatest: int64
  result = DatabaseStatus(
    complete: false,
    cursorLatest: "",
    recommendationIDs: @[]
  )
  logger.log(lvlNotice, &"Will gather up to {amountReview} reviews for game with App ID {ctx.appId}...")
  try:
    for batch in ctx.retrieveReviewsAll(ctx.cursor, amountReview):
      counter.inc
      if counter == 1: timestampLatest = batch.reviews.get()[0].timestamp_created
      var counterDupBatch: int
      logger.log(lvlDebug, "Current batch's cursor: " & batch.cursor)
      result.cursorLatest = batch.cursor
      for review in batch.extractReviews():
        let
          id = review.recommendationid
          jReview = %* review
          jsReview = $ jReview
        if ct.save(id, jsReview):
          if orderedRecommendationIDs.contains(id):
            counterDup.inc
            if counterDup < 5:
              logger.log(lvlDebug, "Duplicate Review ID detected: " & id)
          else:
            orderedRecommendationIDs.incl id
        else:
          logger.log(lvlError, "Failed to save Steam Review to Database:\n" & jReview.pretty)
      if counterDupBatch > 5:
        logger.log(lvlDebug, &"Batch contained {counterDupBatch} duplicate review IDs.")
  except:
    logger.log(lvlWarn, &"Number of reviews gathered by this failed request for game with App ID {ct.collection.name}: " & $orderedRecommendationIDs.len)
    logger.log(lvlError, "Failed to complete retrieval of requested reviews:\n" & getCurrentExceptionMsg())
    finishResult()
    return
  logger.log(lvlInfo, &"Number of reviews gathered by this request for game with App ID {ct.collection.name}: " & $orderedRecommendationIDs.len)
  if counterDup > 0: logger.log(lvlInfo, &"Number of reviews detected as duplicates, which were skipped, for game with App ID {ct.collection.name}: " & $counterDup)
  finishResult()
  result.complete = true

proc saveDbConfig( #TODO: Refactor, as we use DatabaseStatus, anyway.
  ct: CollectionTransaction,
  maxItems: int = dbConfig.maxItems, #TODO: Use dynamic maxReviews from API Request.
  reviewType: ReviewType = dbConfig.reviewType,
  purchaseType: PurchaseType = dbConfig.purchaseType,
  language: Language = dbConfig.language
): bool {.discardable.} =
  let
    config = makeConfigForDB(
      maxItems,
      reviewType,
      purchaseType,
      language
    )
  ct.saveConfig(config)

proc saveDbStatus( #TODO: Refactor, as we use DatabaseStatus, anyway.
  ct: CollectionTransaction,
  complete: bool,
  cursorLatest: string,
  timestampLatest: Timestamp,
  recommendationIDs: HashSet[string],
  tagCloudAvailable: bool = false
): bool {.discardable.} =
  let
    status = makeStatusForDB(
      complete,
      recommendationIDs,
      tagCloudAvailable,
      cursorLatest,
      timestampLatest
    )
  ct.saveStatus(status)

proc saveReviewsAll*(
  ctx: SteamContext,
  amountReview: int,
  amountTag: int,
  reviewType: ReviewType = dbConfig.reviewType,
  purchaseType: PurchaseType = dbConfig.purchaseType,
  language: Language = dbConfig.language
): DatabaseStatus = #TODO: Remove result altogether.
  let
    clt = getRefClt(ctx.appid)
    preStatus = clt.loadDatabaseStatus()
  # Continue from last checkpoint, if previews review gathering was interrupted.
  if preStatus != nil and not preStatus.complete: ctx.cursor = preStatus.cursorLatest
  let
    ct = clt.begin
    status = ctx.saveReviewsAllBase(ct, amountReview)
  result = status
  # logger.log(lvlDebug, &"Number of recommendationIDs contained in Collection for game with App ID {clt.name}: " & $recommendationIDs.len)
  ct.saveDbConfig(
    amountReview,
    reviewType,
    purchaseType,
    language
  )
  ct.saveDbStatus(
    result.complete,
    result.cursorLatest,
    result.timestampLatest,
    result.recommendationIDs.toHashSet
  )
  database.commit(ct)