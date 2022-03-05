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
    api,
    http,
    steam,
    tag
  ],
  std/[
    sets,
    json,
    logging,
    strutils,
    sequtils
  ],
  pkg/[
    timestamp,
    jester
  ]

router requestprocessor:
  post "/api":
    let
      jApiRequest = request.body.parseJson
      appid = jApiRequest.to(ApiRequest).appid
      tagCloud: TagCloud = loadTagCloud($appid)
      apiTagCloud = ApiTagCloud(
        tagsPop: tagCloud.tagsPop.toSeq
        # tagsPop: TagCloud().tagsPop.toSeq
      )
      apiResponse = ApiResponse(
        appid: appid,
        cloud: apiTagCloud,
        timestamp: $initTimestamp()
      )
    resp pretty(%* apiResponse), rawHeaderJson

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