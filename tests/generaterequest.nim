##[
  Generate simple request for testing purposes.
]##

import
  json,
  options,
  model/[
    helper,
    api
  ]

let
  configAdmin = ApiRequestAdmin(
    token: "YWJj",
    ifAvailable: false.some,
    forceFresh: false.some,
    # amountReview: 20_000.some,
    amountReview: 100.some,
    amountTag: 30.some,
    language: Language.english.some,
    reviewType: ReviewType.all.some,
    purchaseType: PurchaseType.all.some
  )
  config = ApiRequest(
    version: 1,
    appid: 730, # Counter Strike: Global Offensive
    admin: configAdmin.some
  )

proc generateRequest*() =
  let
    requestJString = pretty(%* config)
    filePathPayload = "tests/simple_request_payload.json"
  echo "Writing the following payload to " & filePathPayload
  echo requestJString
  echo()
  try: filePathPayload.writeFile(requestJString)
  except: echo "Failed to write payload to file!"