import
  steamreviewessentialiser/[
    apiutils
  ],
  std/[
    strutils,
    strformat,
    options,
    json,
    math,
    os
  ],
  pkg/[
    puppy
  ]

type
  SteamDefect * = object of Defect

  SteamContext * = ref object
    appId         * : string
    cursor        * : string

  SteamReviewQuery * = ref object
    appid         * : string
    filter        * : string
    language      * : string
    day_range     * : Option[string]
    cursor        * : string
    review_type   * : string
    purchase_type * : string
    num_per_page  * : string

func genRequestUrl(query: SteamReviewQuery, fresh = false#[ Set to `true` on first request!]#): Url =
  ## Do not encode `query.cursor` manually! cURL encodes already!
  let
    queries = if fresh: @[
      ("json", "1"),
      ("appid", query.appid),
      ("filter", query.filter),
      ("language", query.language),
      # ("day_range", query.day_range.get("")),
      ("cursor", query.cursor),
      ("review_type", query.review_type),
      ("purchase_type", query.purchase_type),
      ("num_per_page", query.num_per_page)
    ] else: @[
      ("json", "1"),
      ("appid", query.appid),
      ("cursor", query.cursor)
    ]
  Url(
    scheme: "https",
    hostname: "store.steampowered.com",
    path: "/appreviews/" & query.appid,
    query: queries
  )

proc genRequest(ctx: SteamContext, fresh = false#[ Set to `true` on first request!]#): Request =
  let
    query = SteamReviewQuery(
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
    verb: "get"
  )

proc retrieveReviewBatch(ctx: SteamContext, fresh = false#[ Set to `true` on first request!]#): JsonNode =
  let
    req = genRequest(ctx, fresh)
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raise SteamDefect.newException(exceptMsgMsgPostErrorParse)
    respBody = jResp.pretty
  jResp

proc retrieveReviewsAll(ctx: SteamContext): seq[JsonNode] =
  var
    count: int = 0
    cursorPrevious = "*"
  ctx.cursor = cursorPrevious
  let
    log = "reviews_csgo.log".open(fmWrite)
    batchFirst = ctx.retrieveReviewBatch(true)
  cursorPrevious = batchFirst["cursor"].getStr()
  echo batchFirst["query_summary"]["num_reviews"].getInt()
  let
    reviewsTotal = try:
        batchFirst["query_summary"]["total_reviews"].getInt()
      except:
        echo batchFirst.pretty
        raise getCurrentException()
  log.writeLine(batchFirst.pretty)
  log.writeLine("---")
  for i in 1..round(reviewsTotal / 20).toInt() - 1:
    ctx.cursor = cursorPrevious
    let
      fresh = if i == 1: true else: false
      batch = retrieveReviewBatch(ctx, fresh)
    count.inc
    log.writeLine(batch.pretty)
    log.writeLine("---")
    cursorPrevious = batch["cursor"].getStr()
    sleep 10_000


when isMainModule:
  echo retrieveReviewsAll(
    ctx = SteamContext(
      appid: "730"
    )
  )