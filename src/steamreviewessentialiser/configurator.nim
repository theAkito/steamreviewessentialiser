import
  meta,
  json,
  base64,
  os,
  logging,
  strutils,
  model/[
    database,
    helper
  ]

type
  MasterConfig = object
    version     * : string ## Version of this app and its configuration API.
    maxItems    * : int    ## Maximum amount of reviews to be processed. Retrieval of reviews always starts with the most recent, so you will get the most recent N (defined by maxItems) reviews for the particular game.
    maxTags     * : int    ## Amount of tags which are loaded and then sent to the client requesting the Tag Cloud. The more tags are loaded, the bigger the cloud can become.
    intervalAPI * : int    ## The length of the pause between API calls that retrieve Steam reviews in batches, in milliseconds. 10 seconds should be the minimum, to avoid 429s.
    serverName  * : string # App name passed to Jester.
    serverAddr  * : string # Bind address passed to Jester.
    serverPort  * : int    # Port passed to Jester.
    adminToken  * : string ## Base64 encoded password to authorise admin actions, like for example, forcing to reload reviews for a game, even though they already exist.
    debug       * : bool   ## Enable Debug mode.

let
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "configurator" & logMsgSuffix)
  dbConfig* = DatabaseConfig(
    maxItems: 500,
    reviewType: ReviewType.all,
    purchaseType: PurchaseType.all,
    language: Language.english
  )

var
  config* = MasterConfig(
    version: appVersion,
    intervalAPI: 10_000,
    maxItems: 500,
    maxTags: 30,
    serverName: "",
    serverAddr: "",
    serverPort: 50123,
    debug: meta.debug
  )

func pretty(node: JsonNode): string = node.pretty(configIndentation)

func genPathFull(path, name: string): string =
  if path != "": path.normalizePathEnd() & '/' & name else: name

proc getConfig*(): MasterConfig = config

proc genDefaultConfig(path = configPath, name = configName): JsonNode =
  let
    pathFull = path.genPathFull(name)
    conf = %* config
  pathFull.writeFile(conf.pretty())
  conf

proc initConf*(path = configPath, name = configName): bool =
  let
    pathFull = path.genPathFull(name)
    configAlreadyExists = pathFull.fileExists
  if configAlreadyExists:
    logger.log(lvlDebug, "Config already exists! Not generating new one.")
    config = pathFull.parseFile().to(MasterConfig)
    return true
  try:
    genDefaultConfig(path, name)
  except:
    return false
  true