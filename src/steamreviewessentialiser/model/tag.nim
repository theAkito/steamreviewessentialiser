from helper import Language
from sets import
  HashSet,
  OrderedSet

type
  TagCloud * = ref object
    tags        * : HashSet[string]    ## Simple list of all tags, but without duplicates.
    tagsPop     * : OrderedSet[string] ## Tags ordered by popularity. tagsPop.low == most popular, whereas tagsPop.high == least popular.
    tagsLikeDup * : HashSet[string]    ## Tags, which are different technically, but probably mean the same, most likely due to spelling mistake.
    language    * : Language           ## Human language used for tag creation.