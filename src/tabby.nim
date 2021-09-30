# Fast direct CSV/TCV parser for nim.
import strutils, parseutils

type TabbyError* = object of ValueError

type ParseContext = ref object
  i: int
  data: string
  newLine: string
  sep: char

template error(msg: string, i: int) =
  ## Shortcut to raise an exception.
  raise newException(TabbyError, msg & " At offset: " & $i)

proc skipLine(p: ParseContext) =
  let at = p.data.find(p.newLine, p.i)
  if at != -1:
    p.i = at + p.newLine.len

proc skipSpaces(p: ParseContext) =
  while p.i < p.data.len and p.data[p.i] == ' ':
    inc p.i

proc skipSep(p: ParseContext) =
  if p.i < p.data.len and p.data[p.i] == '\n':
    return
  elif p.i < p.data.len and p.data[p.i] == p.sep:
    inc p.i
  else:
    error("Failed to parse, seperator expected.", p.i)

proc parseHook(p: ParseContext, v: var string) =
  p.skipSpaces()
  let start = p.i
  while p.i < p.data.len and p.data[p.i] notin {p.sep, '\n'}:
    inc p.i
  v = p.data[start ..< p.i]

proc parseHook(p: ParseContext, v: var SomeInteger) =
  var num: int
  let chars = parseutils.parseInt(p.data, num, p.i)
  if chars == 0:
    error("Failed to parse a integer.", p.i)
  p.i += chars
  v = num

proc fromCsv*[T](
  data: string,
  objType: type[seq[T]],
  skipHeader = false, # swtich to true
  useTab = false,
  # newLine=Ditect,
): seq[T] =
  ## Read un data seq as a CSV.
  var p = ParseContext()
  p.newLine = "\n"
  p.data = data
  p.sep = ','
  if useTab:
    p.sep = '\t'

  if not skipHeader:
    p.skipLine()

  while p.i < p.data.len:
    var currentRow = T()
    for name, field in currentRow.fieldPairs:
      parseHook(p, field)
      p.skipSep()
    result.add(currentRow)
    p.skipLine()

proc toCsv*[T](
  data: seq[T],
  skipHeader = false,
  useTab = false,
): string =
  ## Writes out data seq as a CSV.
  var seperator = ","
  if useTab:
    seperator = "\t"

  if not skipHeader:
    var headerRow = T()
    for name, field in headerRow.fieldPairs:
      result.add name
      result.add seperator
    result.removeSuffix(seperator)
    result.add("\n")

  for row in data:
    for name, field in row.fieldPairs:
      result.add $field
      result.add seperator
    result.removeSuffix(seperator)
    result.add("\n")
