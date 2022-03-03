##[
  Extract most used keywords from reviews and generate Tag Clouds from them.
]##

import
  meta,
  word,
  model/[
    database,
    tag
  ],
  std/[
    json,
    logging,
    strutils,
    sequtils,
    tables,
    sets
  ]