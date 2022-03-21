import
  meta,
  logging,
  simplerequest,
  os,
  parseopt,
  strutils

let logger = newConsoleLogger(lvlDebug, logMsgPrefix & logMsgInter & "tester" & logMsgSuffix)

var
  srvStart = false
  forceFresh = false

proc showHelp() =
  logger.log(lvlWarn, """Arguments available:""")
  logger.log(lvlWarn, """srv-start""")
  logger.log(lvlWarn, """force-fresh""")

template breakOutOpts(): untyped =
  if not val.isEmptyOrWhitespace(): showHelp()

proc setOpts() =
  for kind, key, val in commandLineParams().getopt():
    case kind
      of cmdArgument:
        # Use `key` to get value of `cmdArgument`.
        showHelp()
      of cmdLongOption, cmdShortOption:
        case key
          of "s", "srv-start":
            breakOutOpts()
            srvStart = true
          of "f", "force-fresh":
            breakOutOpts()
            forceFresh = true
          of "h", "help":
            showHelp()
      of cmdEnd: assert(false)

setOpts()

makeRequest(
  srvStart = srvStart,
  forceFresh = forceFresh
)

