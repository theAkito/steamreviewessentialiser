import
  steamreviewessentialiser/[
    meta,
    apiutils,
    database,
    configurator,
    requestprocessor
  ],
  steamreviewessentialiser/model/[
    helper,
    steam
  ],
  std/[
    logging,
    strutils,
    strformat,
    options,
    json,
    math,
    sets,
    os
  ],
  pkg/[
    puppy,
    nimdbx
  ]

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "master" & logMsgSuffix)

proc run() =
  #[ Initialise configuration file. ]#
  if not initConf(configPath): raise OSError.newException("Config file could neither be found nor generated!")
  listen()

when isMainModule:
  initDb()
  logger.log(lvlInfo, "Starting with the following configuration:\n" & pretty(%* config))
  run()
  closeDb()