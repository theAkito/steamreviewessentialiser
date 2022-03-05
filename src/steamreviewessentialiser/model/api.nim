import
  helper,
  options,
  tag

type
  ApiDefect * = object of Defect

  ApiTagCloud * = ref object
    tags        * : seq[string]    ## Simple list of all tags, but without duplicates.
    tagsPop     * : seq[string] ## Tags ordered by popularity. tagsPop.low == most popular, whereas tagsPop.high == least popular.
    tagsLikeDup * : seq[string]    ## Tags, which are different technically, but probably mean the same, most likely due to spelling mistake.
    language    * : Language           ## Human language used for tag creation.

  ApiRequest * = ref object
    version    * : uint           ## API version.
    appid      * : uint32         ## Client has to search for game by string, select the correct game and then the associated appid will be sent to this server.
    clientType * : ClientType     ## Client type, like e.g. "desktop" or "mobile".
    auth       * : Option[string] ## Authenticate client with server administrator permissions. Base64 encoded string.
    forceFresh * : Option[bool]   ## Requires administrator permissions. Force refresh of review data for this particular game, even when it has already been retrieved in the past.
    language   * : Language       ## Requires administrator permissions. Human language used for tag creation.

  ApiResponse * = ref object
    appid      * : uint32          ## The appid of the game the Tag Cloud is for.
    cloud      * : ApiTagCloud        ## Tag Cloud requested for the appid.
    timestamp  * : string          ## Timestamp as string of the most recent review in the collection used to generate the Tag Cloud. Timestamp is retrieved from the most recent review's `timestamp_created` property.