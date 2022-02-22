from logging import Level

const
  debug             * {.booldefine.} = false
  defaultMsg        * {.strdefine.}  = "Process Finished"
  logMsgPrefix      * {.strdefine.}  = "[$levelname]:[$datetime]"
  logMsgInter       * {.strdefine.}  = " ~ "
  logMsgSuffix      * {.strdefine.}  = " -> "
  appVersion        * {.strdefine.}  = "0.1.0"
  configName        * {.strdefine.}  = "steamreviewessentialiser.json"
  configPath        * {.strdefine.}  = ""
  configIndentation * {.intdefine.}  = 2


func defineLogLevel*(): Level =
  if debug: lvlDebug else: lvlInfo