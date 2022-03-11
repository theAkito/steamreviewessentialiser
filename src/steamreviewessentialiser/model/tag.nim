from helper import
  Language
from tables import
  OrderedTable
from database import
  DatabaseConfig

type
  TagCloud * = ref object
    tagsToPop         * : OrderedTable[string, int] ## Tags ordered by popularity. tagsPop.low == most popular, whereas tagsPop.high == least popular.
    config            * : DatabaseConfig            ## Configuration for the reviews, which the provided TagCloud is generated from. Does reflect what SHOULD be the case, not what necessarily IS the case.
    amountReview      * : int                       ## Amount of reviews used to generate this TagCloud from.
    timestampLatest   * : string                    ## Timestamp as string of the most recent review in the collection used to generate the Tag Cloud. Timestamp is retrieved from the most recent review's `timestamp_created` property.
    timestampUpdate   * : string                    ## When was the last time the collection was refreshed with updated versions of reviews.
    timestampComplete * : string                    ## When was the last time the collection finished gathering the amount of requested reviews for this particular game.