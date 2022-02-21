import
  std/[
    sets,
    json
  ],
  pkg/[
    nimdbx
  ]

{.experimental: "notnil".}

let
  loc = "database"
  flags = {
    NoSubdir,
    Exclusive,
    SafeNoSync
  }
  collFlags = { CreateCollection }
  collKeyType = StringKeys
  collValType = StringValues

var db: Database

# General
proc initDb*() = db = loc.openDatabase(flags = flags)
proc getRefClt*(name: string): Collection not nil = db.openCollection(name, collFlags, collKeyType, collValType)

# Write
proc begin*(clt: Collection not nil): CollectionTransaction = clt.beginTransaction()
proc save*(ct: CollectionTransaction, key, val: string) = ct.put(key, val)
proc commit*(ct: CollectionTransaction) = ct.commit
proc abort*(ct: CollectionTransaction) = ct.abort
# Read
proc beginShow*(clt: Collection not nil): CollectionSnapshot = clt.beginSnapshot()
proc load*(snap: CollectionSnapshot, key: string): string = snap.get(key.asData).asString() # `asString` creates a copy, which survives the transaction.
proc finishShow*(snap: CollectionSnapshot) = snap.finish

# General
proc closeDb*() = db.close