# Fast direct CSV/TCV parser for nim.
import strutils, parseutils

type TabbyError* = object of ValueError

type ParseContext = ref object
  i: int
  data: string
  newLine: string

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
  while p.i < p.data.len and p.data[p.i] == ',':
    inc p.i

proc parseHook(p: ParseContext, v: var string) =
  p.skipSpaces()
  let start = p.i
  while p.i < p.data.len and p.data[p.i] notin {',', '\n'}:
    inc p.i
  v = p.data[start ..< p.i]

proc parseHook(p: ParseContext, v: var SomeInteger) =
  var num: int
  let chars = parseutils.parseInt(p.data, num, p.i)
  if chars == 0:
    error("Failed to parse a integer.", p.i)
  p.i += chars
  v = num

proc formCSV*[T](
  data: string,
  objType: type[seq[T]],
  skipHeader = true
  # header=Ditect,
  # seperator=Ditect
  # newLine=Ditect,
): seq[T] =

  var p = ParseContext()
  p.newLine = "\n"
  p.data = data

  if skipHeader:
    p.skipLine()

  while p.i < p.data.len:
    var currentRow = T()
    for name, field in currentRow.fieldPairs:
      parseHook(p, field)
      p.skipSep()
    result.add(currentRow)
    p.skipLine()
