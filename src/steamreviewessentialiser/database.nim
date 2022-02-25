import
  meta,
  apiutils,
  model/[
    database
  ],
  std/[
    sets,
    json,
    strutils,
    logging
  ],
  pkg/[
    nimdbx,
    timestamp
  ]

from model/steam import SteamReviewItemRes

{.experimental: "notnil".}

type DatabaseDefect = object of Defect

const
  entryNameConfig    = "config"
  entryNameStatus    = "status"
  entryNameTagCloud  = "tagcloud"
  entryNamesMetadata = [
    entryNameConfig,
    entryNameStatus,
    entryNameTagCloud
  ]

let
  defaultTimestamp = initTimestamp(0)
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "database" & logMsgSuffix)
  loc = "database" #TODO: Make configurable.
  flags = {
    # NoSubdir,
    Exclusive,
    SafeNoSync
  }
  collFlags = { CreateCollection }
  putFlags = { NoDupData }
  collKeyType = StringKeys
  collValType = BlobValues

var db: Database

func isEntryMetadata(entryName: string): bool = entryNamesMetadata.contains(entryName)
func isEntryReview(entryName: string): bool = result = try: entryName.parseInt() != 0 except: false

proc makeStatus(
  complete: bool,
  recommendationIDs: seq[string],
  tagCloudAvailable: bool = false,
  cursorLatest: string = "*"
): DatabaseStatus =
  let
    status = DatabaseStatus(
      complete: complete,
      tagCloudAvailable: tagCloudAvailable,
      cursorLatest: cursorLatest,
      recommendationIDs: recommendationIDs,
      timestampUpdate: initTimestamp(),
      timestampComplete: if complete: initTimestamp() else: defaultTimestamp,
    )
  status

proc makeStatusForDB*(
  complete: bool,
  recommendationIDs: seq[string],
  tagCloudAvailable: bool = false,
  cursorLatest: string = "*"
): string =
  $ %* makeStatus(
    complete,
    recommendationIDs,
    tagCloudAvailable,
    cursorLatest
  )

# General
proc initDb*() = db = loc.openDatabase(flags = flags)
proc getRefClt*(name: string): Collection not nil = db.openCollection(name, collFlags, collKeyType, collValType)

# Write
proc begin*(clt: Collection not nil): CollectionTransaction = clt.beginTransaction()
proc save*(ct: CollectionTransaction, key, val: string): bool =
  try: ct.put(key, val, putFlags) except: false
proc saveStatus*(ct: CollectionTransaction, val: string): bool = ct.save(entryNameStatus, val)
proc commit*(ct: CollectionTransaction) = nimdbx.commit(ct)
proc abort*(ct: CollectionTransaction) = nimdbx.abort(ct)
# Read
proc beginShow*(clt: Collection not nil): CollectionSnapshot = clt.beginSnapshot()
proc load*(snap: CollectionSnapshot, key: string): string = snap.get(key.asData).asString() # `asString` creates a copy, which survives the transaction.
proc finishShow*(snap: CollectionSnapshot) = snap.finish

# General
proc closeDb*() = db.close

# Utils
iterator loadAllReviews*(cltName: string): SteamReviewItemRes =
  let
    clt = getRefClt(cltName)
    snap = clt.beginShow()
  defer: snap.finishShow()
  var cursor = snap.makeCursor()
  for key, val in cursor.pairs:
    if not key.isEntryReview(): continue
    try:
      yield val.parseJson().to(SteamReviewItemRes)
    except:
      logger.log(lvlDebug, exceptMsgMsgPostErrorParse)
      continue

when isMainModule:
  import os
  initDb()
  let
    clt = getRefClt("730")
    snap = beginShow(clt)
  var
    cursor = snap.makeCursor()
    counter = 0
  while cursor.next():
    counter.inc
    # echo "KEY: " & pretty(cursor.key.asString().parseJson())
    echo "REVIEW: " & pretty(cursor.value.asString().parseJson(){"review"})
    if counter >= 5: break
    sleep 10_000
  echo "Reviews displayed: " & $counter
  snap.finishShow()
  closeDb()