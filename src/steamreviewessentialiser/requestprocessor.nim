##[
  Process requests coming from clients.
]##

# https://github.com/dom96/jester#custom-router

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
    jester
  ]

router requestprocessor:
  post "/api":
    resp pretty(request.body.parseJson), rawHeaderJson

proc listen*() =
  let
    port = 1337.Port
    settings = newSettings(port)
  var srv = initJester(requestprocessor, settings)
  srv.serve