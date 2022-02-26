import
  meta,
  json,
  database,
  logging,
  nimdbx

let logger = newConsoleLogger(lvlDebug, logMsgPrefix & logMsgInter & "tester" & logMsgSuffix)

initDb()
let
  clt = getRefClt("730")
  # snap = clt.beginShow

try:
  let status = clt.loadDatabaseStatus()
  logger.log(lvlNotice, "Database Status:\n" & pretty(%* status))
  logger.log(lvlNotice, "recommendationIDs len: " & $status.recommendationIDs.len)
except:
  logger.log(lvlError, "Failed to load Database Status.")

# snap.finishShow
closeDb()