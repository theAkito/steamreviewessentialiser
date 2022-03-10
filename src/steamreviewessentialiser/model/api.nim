import
  helper,
  options,
  tag

type
  ApiDefect * = object of Defect

  ApiRequestAdmin * = ref object
    ## Any option provided here requires administrator permissions,
    ## i.e. successful authentication through the provided `adminToken`.
    token        * : string               ## Authenticate client with server administrator permissions. Base64 encoded string.
    ifAvailable  * : Option[bool]         ## Do not gather review data and save to database, if this particular game's tag cloud data is not yet available in the database. Default: false (Will gather review data, if none is found in the database & authentication as administrator succeeded.)
    forceFresh   * : Option[bool]         ## Force refresh of review data for this particular game, even when it has already been retrieved in the past.
    amountReview * : Option[int]          ## Amount of reviews to retrieve, which the TagCloud generation will be based on. The more reviews are gathered, the longer it takes, but the result will be more precise on average across all possible reviews.
    amountTag    * : Option[int]          ## Amount of tags the TagCloud should at least contain. If not enough reviews are found to generate the TagCloud from, then less tags than requested might be sent.
    language     * : Option[Language]     ## Which human language is requested. Default: "english"
    reviewType   * : Option[ReviewType]   ## Which review type is requested. Default: "all" (positive & negative)
    purchaseType * : Option[PurchaseType] ## Which purchase type is requested. Default: "all" (Non-Steam & Steam)

  ApiRequest * = ref object
    version      * : uint                 ## API version.
    appid        * : uint32               ## Client has to search for game by string, select the correct game and then the associated appid will be sent to this server.
    clientType   * : ClientType           ## Client type, like e.g. "desktop" or "mobile".
    admin        * : Option[ApiRequestAdmin]

  ApiResponse * = ref object
    appid        * : uint32               ## The appid of the game the Tag Cloud is for.
    success      * : bool                 ## Whether the request was successful. Can fail, when the game is not found, or because gathering is interrupted, when requesting a forced refresh, etc.
    cloud        * : TagCloud             ## Tag Cloud requested for the appid.