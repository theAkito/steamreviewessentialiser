import
  strutils
from puppy import Header

const
  exceptMsgMsgPostErrorParse* = "Unable to read revuew due to JSON parsing error!"
  exceptMsgMsgPostErrorAPI* = "Unable to retrieve review due to an API error!"
  headerJson* = Header(key: "Content-type", value: "application/json")
  rawHeaderJson* = "Content-Type: application/json"

func is20x*(code: int): bool = code.intToStr().startsWith("20")