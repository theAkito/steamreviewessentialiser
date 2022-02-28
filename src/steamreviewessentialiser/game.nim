##[
  Retrieve information about Steam games.
  Mainly needed for searching a game through human titles and then matching their unique App IDs.
]##

import
  meta,
  apiutils,
  model/[
    steam
  ],
  std/[
    json,
    logging,
    strutils
  ],
  pkg/[
    puppy
  ]

const
  url = "https://api.steampowered.com/ISteamApps/GetAppList/v0002"

let
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "game" & logMsgSuffix)
  req = Request(
    url: url.parseUrl,
    verb: "get",
    headers: @[headerJson]
  )

proc retrieveApps*(): seq[SteamAppRes] =
  let
    req = req
    resp = req.fetch()
    jResp =
      try: resp.body.parseJson()["applist"]
      except: raise SteamDefect.newException(exceptMsgMsgPostErrorParse)
  var failApp: JsonNode
  try:
    for jApp in jResp["apps"].getElems:
      failApp = jApp
      result.add jApp.to(SteamAppRes)
  except:
    logger.log(lvlFatal, "Failed to parse Steam App item:\n" & failApp.pretty)
    raise getCurrentException()

when isMainModule:
  import random, sequtils
  randomize()
  var appSelected: SteamAppRes
  let
    apps = retrieveApps().filterIt(it.name.toLowerAscii.contains("warhammer"))
  appSelected = apps[apps.high.rand]
  echo pretty(%* appSelected)