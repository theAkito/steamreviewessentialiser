from json import JsonNode
from options import Option

type
  SteamDefect * = object of Defect

  SteamContext * = ref object
    appId         * : string
    cursor        * : string ## Is managed automatically. Providing the appId is enough.

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
    total_positive    * : Option[int]
    total_negative    * : Option[int]
    total_reviews     * : Option[int]

  SteamReviewAuthorRes * = ref object
    steamid                 * : string
    num_games_owned         * : int64
    num_reviews             * : int64
    playtime_forever        * : int64
    playtime_last_two_weeks * : int64
    playtime_at_review      * : int64
    last_played             * : int64

  SteamReviewItemRes * = ref object
    recommendationid            * : string
    author                      * : SteamReviewAuthorRes
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

  SteamAppRes * = ref object
    appid * : uint32
    name  * : string

  SteamAppsRes * = ref object
    apps * : seq[SteamAppRes]

  SteamAppListRes * = ref object
    applist * : SteamAppsRes