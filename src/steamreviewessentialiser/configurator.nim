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
    version                   *: string
    maxItems                  *: int
    intervalAPI               *: int
    debug                     *: bool

let
  jNodeEmpty = newJObject()
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "configurator" & logMsgSuffix)
  config* = MasterConfig(
    version: appVersion,
    intervalAPI: 10_000,
    maxItems: 500,
    debug: meta.debug
  )
  dbConfig* = DatabaseConfig(
    maxItems: 500,
    reviewType: ReviewType.all,
    purchaseType: PurchaseType.all,
    language: Language.english
  )