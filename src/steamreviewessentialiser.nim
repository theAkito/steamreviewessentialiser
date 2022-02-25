import
  steamreviewessentialiser/[
    meta,
    apiutils,
    database,
    configurator
  ],
  steamreviewessentialiser/model/[
    steam
  ],
  std/[
    logging,
    strutils,
    strformat,
    options,
    json,
    math,
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
      ("cursor", query.cursor)
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
        ("purchase_type", query.purchase_type),
        ("num_per_page", query.num_per_page)
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

iterator retrieveReviewsAll(ctx: SteamContext): SteamReviewsRes {.inline.} =
  var
    count: int = 0
    cursorPrevious = "*"
  ctx.cursor = cursorPrevious
  let
    batchFirst = ctx.retrieveReviewBatch(true)
  cursorPrevious = batchFirst.cursor
  let
    reviewsTotal = try:
        batchFirst.query_summary.get().total_reviews.get()
      except:
        logger.log(lvlFatal, "Failed to retrieve total amount of Steam Reviews:\n" & pretty(%* batchFirst))
        raise getCurrentException()
  for i in 1..genBatchIterLimit(reviewsTotal, 100):
    ctx.cursor = cursorPrevious
    let
      fresh = i == 1
      batch = ctx.retrieveReviewBatch(fresh)
    count.inc
    yield batch
    cursorPrevious = batch.cursor
    sleep config.intervalAPI

proc saveReviewsAllBase(ctx: SteamContext, ct: CollectionTransaction) =
  ##[
    Requires an open CollectionTransaction.
  ]##
  for batch in ctx.retrieveReviewsAll:
    for review in batch.extractReviews():
      let
        jReview = %* review
        jsReview = $ jReview
      if not ct.save(review.recommendationid, jsReview):
        logger.log(lvlError, "Failed to save Steam Review to Database:\n" & jReview.pretty)

proc saveReviewsAll(ctx: SteamContext) =
  let
    clt = getRefClt(ctx.appid)
    ct = clt.begin
  ctx.saveReviewsAllBase(ct)
  database.commit(ct)

when isMainModule:
  initDb()
  let ctx = SteamContext(
    appid: "730"
  )
  ctx.saveReviewsAll()
  closeDb()