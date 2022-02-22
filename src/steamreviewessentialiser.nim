import
  steamreviewessentialiser/[
    apiutils,
    database
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
    puppy,
    nimdbx
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

  SteamQuerySummaryRes * = ref object
    num_reviews       * : Option[int]
    review_score      * : Option[int]
    review_score_desc * : Option[string]
    total_positive    * : Option[int64]
    total_negative    * : Option[int64]
    total_reviews     * : Option[int64]

  SteamReviewAutherRes * = ref object
    steamid                 * : string
    num_games_owned         * : int64
    num_reviews             * : int64
    playtime_forever        * : int64
    playtime_last_two_weeks * : int64
    playtime_at_review      * : int64
    last_played             * : int64

  SteamReviewItemRes * = ref object
    recommendationid            * : string
    author                      * : SteamReviewAutherRes
    language                    * : string
    review                      * : string
    timestamp_created           * : int64
    timestamp_updated           * : int64
    voted_up                    * : bool
    votes_up                    * : int64
    votes_funny                 * : int64
    weighted_vote_score         * : JsonNode # JString or JInt
    comment_count               * : int64
    steam_purchase              * : bool
    received_for_free           * : bool
    written_during_early_access * : bool
    developer_response          * : Option[string]
    timestamp_dev_responded     * : Option[string]

  SteamReviewsRes * = ref object
    success       * : int
    query_summary * : Option[SteamQuerySummaryRes]
    cursor        * : string
    reviews       * : Option[seq[SteamReviewItemRes]]

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

func extractReviews(batch: SteamReviewsRes): seq[SteamReviewItemRes] = batch.reviews.get(@[])

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
    verb: "get",
    headers: @[headerJson]
  )

proc retrieveReviewBatch(ctx: SteamContext, fresh = false#[ Set to `true` on first request!]#): SteamReviewsRes =
  let
    req = genRequest(ctx, fresh)
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raise SteamDefect.newException(exceptMsgMsgPostErrorParse)
    respBody = jResp.pretty
  try:
    jResp.to(SteamReviewsRes)
  except:
    echo jResp{"query_summary"}.pretty
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
        echo pretty(%* batchFirst)
        raise getCurrentException()
  for i in 1..round(reviewsTotal.int / 100).toInt() - 1:
    ctx.cursor = cursorPrevious
    let
      fresh = if i == 1: true else: false
      batch = ctx.retrieveReviewBatch(fresh)
    count.inc
    yield batch
    cursorPrevious = batch.cursor
    sleep 10_000

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
        echo "Failed to save review:\n" & jReview.pretty

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