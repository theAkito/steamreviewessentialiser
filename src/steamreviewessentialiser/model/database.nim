type
  DatabaseConfig * = ref object
    maxItems            * : string ## How many reviews should be allowed to be saved for this particular game.

  DatabaseStatus * = ref object
    complete            * : string ## Whether the review gathering ever completely fetched and saved all reviews for this particular game.
    cursorLatest        * : string ## Which cursor position to continue gathering from, if gathering wasn't finished, yet.
    timestampUpdate     * : int64  ## When was the last time the collection was refreshed with updated versions of reviews.
    timestampComplete   * : int64  ## When was the last time the collection finished gathering all reviews for this particular game.