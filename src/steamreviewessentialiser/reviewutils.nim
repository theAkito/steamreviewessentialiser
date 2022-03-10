import
  meta,
  apiutils,
  database,
  configurator,
  model/[
    helper,
    steam
  ]

func getTimestampCreated*(review: SteamReviewItemRes): int64 = review.timestamp_created