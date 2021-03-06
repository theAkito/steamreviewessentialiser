##[
  These models are supposed to be converted to JObjects and then saved to provide additional information in each collection, per game.
]##

import helper
from timestamp import Timestamp

type
  DatabaseConfig * = ref object          ## What SHOULD be happening.
    maxItems            * : int          ## How many reviews should be allowed to be saved for this particular game.
    reviewType          * : ReviewType   ## Which review type is allowed to be saved. Default: "all" (positive & negative)
    purchaseType        * : PurchaseType ## Which purchase type is allowed to be saved. Default: "all" (Non-Steam & Steam)
    language            * : Language     ## Which human language is allowed to be saved. Default: "english"

  DatabaseStatus * = ref object          ## What IS happening.
    complete            * : bool         ## Whether the review gathering ever completely fetched and saved all reviews for this particular game.
    tagCloudAvailable   * : bool         ## Whether the generation of the Tag Cloud was finished and is available.
    cursorLatest        * : string       ## Which cursor position to continue gathering from, if gathering wasn't finished, yet.
    recommendationIDs   * : seq[string]  ## A list of recommendationids, contained in this collection. Use, to quickly know which reviews are already known/saved and which are newly composed, i.e. gathered from the API, but not yet contained in this sequence. Length of this sequence must correspond to amount of reviews saved in this collection.
    timestampLatest     * : Timestamp    ## Timestamp of the most recent review in the collection. Timestamp is retrieved from the most recent review's `timestamp_created` property.
    timestampUpdate     * : Timestamp    ## When was the last time the collection was refreshed with updated versions of reviews.
    timestampComplete   * : Timestamp    ## When was the last time the collection finished gathering the amount of requested reviews for this particular game.

when isMainModule:
  import json
  echo pretty(%* DatabaseConfig(
    #[]#
  ))