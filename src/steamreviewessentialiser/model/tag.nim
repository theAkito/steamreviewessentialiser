from helper import
  Language
from tables import
  OrderedTable
from database import
  DatabaseConfig

type
  TagCloud * = ref object
    tagsToPop   * : OrderedTable[string, int] ## Tags ordered by popularity. tagsPop.low == most popular, whereas tagsPop.high == least popular.
    config      * : DatabaseConfig             ## Tags ordered by popularity. tagsPop.low == most popular, whereas tagsPop.high == least popular.
    language    * : Language             ## Human language used for tag creation.