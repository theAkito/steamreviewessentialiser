import
  steamreviewessentialiser/[
    meta,
    apiutils,
    database,
    configurator
  ],
  steamreviewessentialiser/model/[
    helper,
    steam
  ],
  std/[
    logging,
    strutils,
    strformat,
    options,
    json,
    math,
    sets,
    os
  ],
  pkg/[
    puppy,
    nimdbx
  ]

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "master" & logMsgSuffix)

func genBatchAmountBonus(total, batchSize: int): int =
  if total mod batchSize == 0: 0 else: 1

proc genBatchAmount(total, batchSize: int): int = floor(total / batchSize).toInt() + genBatchAmountBonus(total, batchSize)

proc genBatchIterLimit(reviewsTotal, batchSize: int): int =
  let
    reviewsTotalBatches = genBatchAmount(reviewsTotal, batchSize)
    maxBatches = genBatchAmount(config.maxItems, batchSize)
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
      ("num_per_page", query.num_per_page)
    ]
    queryDayRangePartial = query.day_range.get("")
    optionalQueries = try:
      if queryFilter == "all" and not queryDayRangePartial.isEmptyOrWhitespace:
        @[("day_range", queryDayRangePartial)] else: @[]
    except: @[]
    queries = if fresh:
      defaultQueries &
      optionalQueries & @[
        ("filter", queryFilter),
        ("language", query.language),
        ("review_type", query.review_type),
        ("purchase_type", query.purchase_type)
      ] else: defaultQueries
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

iterator retrieveReviewsAll(ctx: SteamContext, cursorProvided = "*"): SteamReviewsRes {.inline.} =
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
  for i in 1..genBatchIterLimit(reviewsTotal, reviewsPerBatch):
    ctx.cursor = cursorPrevious
    let
      fresh = i == 1
      batch = ctx.retrieveReviewBatch(fresh)
    try: logger.log(lvlDebug, "Actual number of reviews retrieved in this batch: " & $batch.query_summary.get().num_reviews.get())
    except: continue
    count.inc
    yield batch
    cursorPrevious = batch.cursor
    sleep config.intervalAPI

proc saveReviewsAllBase(ctx: SteamContext, ct: CollectionTransaction): (bool, string, HashSet[string]) {.raises: [Exception #[Due to Lumberjack.]#].} =
  ##[
    Requires an open CollectionTransaction.
  ]##
  var counterDup: int
  result = (false, "", initHashSet[string](config.maxItems))
  try:
    for batch in ctx.retrieveReviewsAll(ctx.cursor):
      logger.log(lvlDebug, "Current batch's cursor: " & batch.cursor)
      result[1] = batch.cursor
      for review in batch.extractReviews():
        let
          id = review.recommendationid
          jReview = %* review
          jsReview = $ jReview
        if ct.save(id, jsReview):
          if result[2].contains(id):
            counterDup.inc
            logger.log(lvlDebug, "Duplicate Review ID detected: " & id)
          else:
            result[2].incl id
        else:
          logger.log(lvlError, "Failed to save Steam Review to Database:\n" & jReview.pretty)
  except:
    logger.log(lvlError, "Failed to complete retrieval of requested reviews:\n" & getCurrentExceptionMsg())
    return
  logger.log(lvlInfo, &"Number of reviews gathered by this request for game with App ID {ct.collection.name}: " & $result[2].len)
  logger.log(lvlInfo, &"Number of reviews detected as duplicates, which were skipped, for game with App ID {ct.collection.name}: " & $counterDup)
  result[0] = true

proc saveDbConfig(
  ct: CollectionTransaction,
  maxItems: int = dbConfig.maxItems,
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

proc saveDbStatus(
  ct: CollectionTransaction,
  complete: bool,
  cursorLatest: string,
  recommendationIDs: HashSet[string],
  tagCloudAvailable: bool = false
): bool {.discardable.} =
  let
    status = makeStatusForDB(
      complete,
      recommendationIDs,
      tagCloudAvailable,
      cursorLatest
    )
  ct.saveStatus(status)

proc saveReviewsAll(ctx: SteamContext) =
  let
    clt = getRefClt(ctx.appid)
    preStatus = clt.loadDatabaseStatus()
  # Continue from last checkpoint, if previews review gathering was interrupted.
  if preStatus != nil and not preStatus.complete: ctx.cursor = preStatus.cursorLatest
  let
    ct = clt.begin
    (complete, cursor, recommendationIDs) = ctx.saveReviewsAllBase(ct)
  logger.log(lvlDebug, &"recommendationIDs contained in Collection for game with App ID {clt.name}: " & $recommendationIDs)
  ct.saveDbConfig()
  ct.saveDbStatus(
    complete,
    cursor,
    recommendationIDs
  )
  database.commit(ct)

when isMainModule:
  initDb()
  let ctx = SteamContext(
    appid: "730"
  )
  ctx.saveReviewsAll()
  closeDb()