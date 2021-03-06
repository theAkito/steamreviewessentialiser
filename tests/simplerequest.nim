##[
  Apply simple request created by request generator for testing purposes.
]##

import
  meta,
  apiutils,
  strutils,
  strformat,
  options,
  puppy,
  times,
  json,
  os,
  osproc,
  generaterequest,
  logging,
  model/[
    api
  ]

let logger = newConsoleLogger(lvlDebug, logMsgPrefix & logMsgInter & "simplerequest" & logMsgSuffix)

var srv: Process

template terminateSrv() =
  if srvStart: srv.terminate() else: discard

proc runServer(): Process =
  discard execCmdEx("""nimble dbuild""")
  startProcess(command = "steamreviewessentialiser", workingDir = "", options = { poStdErrToStdOut, poParentStreams })

proc makeRequest*(srvStart: bool, forceFresh: bool) =
  if srvStart:
    logger.log(lvlInfo, "Starting Server...")
    srv = runServer()
    logger.log(lvlInfo, "Waiting for Server to finish starting up...")
    sleep 10_000 ## Wait for the server to finish starting up.
  else:
    logger.log(lvlInfo, "NOT starting server. Server is expected to be running, already.")
  logger.log(lvlInfo, "Generate API request...")
  generateRequest()
  let
    apiRequest = "tests/simple_request_payload.json".readFile.parseJson.to(ApiRequest)
    apiRequestAdmin = apiRequest.admin
  if apiRequestAdmin.isSome:
    apiRequestAdmin.get().forceFresh = forceFresh.some
  let
    req = Request(
      url: parseUrl("localhost:50123/api"),
      verb: "POST",
      body: $ %* apiRequest,
      headers: @[headerJson]
    )
  block:
    let
      timeStart = now()
      resp = req.fetch()
      body = resp.body
    if body.isEmptyOrWhitespace:
      logger.log(lvlError, "Response is empty. Is the server running?")
      logger.log(lvlError, "Error occurred when trying to connect to the server: " & resp.error)
      terminateSrv()
      break
    else:
      logger.log(lvlNotice, body)
      echo()
    let timeFinish = now()
    echo &"Request took {timeFinish - timeStart}."
  terminateSrv()
  if srvStart and waitForExit(srv) == 143: logger.log(lvlInfo, "Successfully terminated server!")