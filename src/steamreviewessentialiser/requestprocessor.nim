##[
  Process requests coming from clients.
]##

# https://github.com/dom96/jester#custom-router

import
  meta,
  apiutils,
  configurator,
  cloudor,
  model/[
    steam,
    tag
  ],
  std/[
    json,
    logging,
    strutils
  ],
  pkg/[
    jester
  ]

router requestprocessor:
  post "/api":
    resp pretty(request.body.parseJson), rawHeaderJson

proc listen*() =
  let
    name = config.serverName
    bindAddr = config.serverAddr
    port = config.serverPort.Port
    settings = newSettings(
      appName = name,
      bindAddr = bindAddr,
      port = port
    )
  var srv = initJester(requestprocessor, settings)
  srv.serve