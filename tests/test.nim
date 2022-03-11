import
  meta,
  json,
  database,
  logging,
  nimdbx,
  simplerequest,
  os,
  osproc,
  strutils

let logger = newConsoleLogger(lvlDebug, logMsgPrefix & logMsgInter & "tester" & logMsgSuffix)

makeRequest(
  srvStart = try: commandLineParams()[0].parseBool except: false,
  forceFresh = try: commandLineParams()[1].parseBool except: false
)

