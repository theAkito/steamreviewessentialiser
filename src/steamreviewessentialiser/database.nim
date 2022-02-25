import
  std/[
    sets,
    json
  ],
  pkg/[
    nimdbx
  ]

{.experimental: "notnil".}

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
  loc = "database"
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

# General
proc initDb*() = db = loc.openDatabase(flags = flags)
proc getRefClt*(name: string): Collection not nil = db.openCollection(name, collFlags, collKeyType, collValType)

# Write
proc begin*(clt: Collection not nil): CollectionTransaction = clt.beginTransaction()
proc save*(ct: CollectionTransaction, key, val: string): bool =
  try: ct.put(key, val, putFlags) except: false
proc commit*(ct: CollectionTransaction) = nimdbx.commit(ct)
proc abort*(ct: CollectionTransaction) = nimdbx.abort(ct)
# Read
proc beginShow*(clt: Collection not nil): CollectionSnapshot = clt.beginSnapshot()
proc load*(snap: CollectionSnapshot, key: string): string = snap.get(key.asData).asString() # `asString` creates a copy, which survives the transaction.
proc finishShow*(snap: CollectionSnapshot) = snap.finish

# General
proc closeDb*() = db.close

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