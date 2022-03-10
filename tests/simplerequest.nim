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
  model/[
    api
  ]

template terminateSrv() = srv.terminate()

proc runServer(): Process =
  discard execCmdEx("""nimble dbuild""")
  startProcess(command = "steamreviewessentialiser", workingDir = "", options = { poStdErrToStdOut, poParentStreams })

proc makeRequest*() =
  echo "Starting Server..."
  let srv = runServer()
  echo "Waiting for Server to finish starting up..."
  sleep 10_000 ## Wait for the server to finish starting up.
  echo "Generate API request..."
  generateRequest()
  let
    apiRequest = "tests/simple_request_payload.json".readFile.parseJson.to(ApiRequest)
    apiRequestAdmin = apiRequest.admin
  if apiRequestAdmin.isSome:
    apiRequestAdmin.get().forceFresh = try: commandLineParams()[0].parseBool.some except: false.some
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
      echo "Response is empty. Is the server running?"
      echo "Error occurred when trying to connect to the server: " & resp.error
      terminateSrv()
      break
    else:
      echo body
      echo()
    let
      timeFinish = now()
    echo &"Request took {timeFinish - timeStart}."
  terminateSrv()
  if waitForExit(srv) == 143: echo "Success!"