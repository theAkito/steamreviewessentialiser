import
  helper,
  options

type
  ApiDefect * = object of Defect

  ApiRequest * = object of Defect
    version    * : uint           ## API version.
    appid      * : uint32         ## Client has to search for game by string, select the correct game and then the associated appid will be sent to this server.
    clientType * : ClientType     ## Client type, like e.g. "desktop" or "mobile".
    auth       * : Option[string] ## Authenticate client with server administrator permissions. Base64 encoded string.
    forceFresh * : Option[bool]   ## Requires administrator permissions. Force refresh of review data for this particular game, even when it has already been retrieved in the past.