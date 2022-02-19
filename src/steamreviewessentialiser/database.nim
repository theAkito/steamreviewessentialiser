import
  std/[
    sets
  ],
  pkg/[
    nimdbx
  ]

let
  loc = "database"
  flags = {
    NoSubdir,
    Exclusive,
    SafeNoSync
  }

var
  db: Database

loc.eraseDatabase()
db = loc.openDatabase(flags = flags)