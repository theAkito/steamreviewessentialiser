import
  meta,
  json,
  database,
  logging,
  nimdbx,
  simplerequest,
  os,
  osproc

let logger = newConsoleLogger(lvlDebug, logMsgPrefix & logMsgInter & "tester" & logMsgSuffix)

makeRequest()

