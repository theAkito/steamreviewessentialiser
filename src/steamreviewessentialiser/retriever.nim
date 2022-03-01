##[
  Base Procs as a Steam API interface.
]##

import
  meta,
  apiutils,
  model/[
    http
  ],
  std/[
    json,
    logging,
    strutils,
    strformat
  ],
  pkg/[
    puppy
  ]

let
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "retriever" & logMsgSuffix)

proc retrieve*(req: Request, typ: typedesc): typ {.raises: [].} =
  let
    req = req
    resp = req.fetch()
    jResp =
      try: resp.body.parseJson()
      except: raise HttpDefect.newException(exceptMsgMsgPostErrorParse)
  try:
    jResp.to(typ)
  except:
    logger.log(lvlFatal, &"Failed to parse HTTP response into model with name {typ.name}:\n" & jResp.pretty)
    raise getCurrentException()