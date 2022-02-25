import
  meta,
  json,
  base64,
  os,
  logging,
  strutils

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