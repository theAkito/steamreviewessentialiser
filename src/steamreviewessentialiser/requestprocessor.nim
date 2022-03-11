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
    tag
  ],
  std/[
    json,
    options,
    logging,
    strutils
  ],
  pkg/[
    timestamp,
    jester
  ]

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "requestprocessor" & logMsgSuffix)

proc auth(token: string): bool = config.adminToken == token

router requestprocessor:
  post "/api":
    let
      jApiRequest = request.body.parseJson
      apiRequest = jApiRequest.to(ApiRequest)
      appid = apiRequest.appid
      token = apiRequest.admin.get().token
      forceFresh = if token.auth: apiRequest.admin.get().forceFresh.get(false) else: false
      tagCloud = loadTagCloud(
        $appid,
        forceFresh,
        apiRequest.admin.get().amountReview.get(), #TODO Try-Catch this.
        apiRequest.admin.get().amountTag.get(), #TODO Try-Catch this.
        apiRequest.admin.get().reviewType.get(), #TODO Try-Catch this.
        apiRequest.admin.get().purchaseType.get(), #TODO Try-Catch this.
        apiRequest.admin.get().language.get() #TODO Try-Catch this.
      )
      apiResponse = ApiResponse(
        appid: appid,
        cloud: tagCloud
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