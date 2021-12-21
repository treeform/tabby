# Fast direct CSV/TCV parser for nim.
import strutils, parseutils, strformat

type TabbyError* = object of ValueError

type ParseContext = ref object
  i: int
  header: seq[string]
  data: string
  lineEnd: string
  separator: string

template error(msg: string, i: int) =
  ## Shortcut to raise an exception.
  raise newException(TabbyError, msg & " At offset: " & $i)

# proc atlineEnd(p: ParseContext): bool =
#   ## Tests if the parser context is at a new line.
#   return p.data[p.i] != '\n'

proc isNext(p: ParseContext, str: string): bool =
  ## Tests if the a str comes next.
  for i, c in str:
    if p.i + i >= p.data.len:
      return false
    if p.data[p.i + i] != c:
      return false
  return true

proc skipLine(p: ParseContext) =
  ## Skips this line.
  let at = p.data.find(p.lineEnd, p.i)
  if at != -1:
    p.i = at + p.lineEnd.len

proc skipSpaces(p: ParseContext) =
  ## Skips spaces to next token.
  while p.i < p.data.len and p.data[p.i] == ' ':
    inc p.i

proc skipSep(p: ParseContext) =
  ## Skips current separator.
  if p.i < p.data.len and p.isNext(p.lineEnd):
    return
  elif p.i < p.data.len and p.isNext(p.separator):
    p.i += p.separator.len
  else:
    if p.i >= p.data.len:
      error(&"Failed to parse, end of data reached.", p.i)
    else:
      error(&"Failed to parse, separator expected, got: {p.data[p.i]}.", p.i)

proc parseHook(p: ParseContext, v: var string) =
  ## Parse hook for string.
  let start = p.i
  if p.data[p.i] in {'"', '\''}:
    # "quoted string"
    let quote = p.data[p.i]
    inc p.i
    while p.i < p.data.len and p.data[p.i] != quote:
      if p.data[p.i] == '\\':
        # handle escape quote
        inc p.i
        let c = p.data[p.i]
        case c:
          of '"', '\\', '/': v.add(c)
          of 'b': v.add '\b'
          of 'f': v.add '\f'
          of 'n': v.add '\n'
          of 'r': v.add '\r'
          of 't': v.add '\t'
          else: v.add c
        inc p.i
      else:
        v.add p.data[p.i]
        inc p.i
    inc p.i
  else:
    # plain string
    while p.i < p.data.len and not (p.isNext(p.separator) or p.isNext(p.lineEnd) or p.isNext(" ")):
      inc p.i
    v = p.data[start ..< p.i]

proc parseHook(p: ParseContext, v: var SomeInteger) =
  ## Parse hook for integer.
  var num: int
  let chars = parseutils.parseInt(p.data, num, p.i)
  if chars == 0:
    error("Failed to parse a integer.", p.i)
  p.i += chars
  v = num

proc parseHook(p: ParseContext, v: var bool) =
  ## Parse hook for boolean.
  var str: string
  p.parseHook(str)
  v = str.toLowerAscii() == "true"

proc fromCsv*[T](
  data: string,
  objType: type[seq[T]],
  header = newSeq[string](),
  hasHeader = true,
  lineEnd = "\n",
  separator = ","
): seq[T] =
  ## Read data seq as a CSV.
  ## * header - use this header to parse
  ## * hasHeader - does the current data have a header,
  ##   will be skipped if header is set.
  ## * useTab - use tabs instead of commas.
  var p = ParseContext()
  p.data = data
  p.header = header
  var userHeader = header.len != 0
  p.lineEnd = lineEnd
  p.separator = separator

  if hasHeader:
    while not p.isNext(p.lineEnd):
      var name: string
      p.skipSpaces()
      p.parseHook(name)
      p.skipSpaces()
      if not userHeader:
        p.header.add(name)
      p.skipSep()
    p.skipLine()
  else:
    if not userHeader:
      for name, field in T().fieldPairs:
        p.header.add(name)

  doAssert p.header.len != 0

  while p.i < p.data.len:
    var currentRow = T()
    for headerName in p.header:
      for name, field in currentRow.fieldPairs:
        if headerName == name:
          p.skipSpaces()
          parseHook(p, field)
          p.skipSpaces()
          if p.i == p.data.len:
            result.add(currentRow)
            return
          p.skipSep()
          break
    result.add(currentRow)
    p.skipLine()


type PrintContext = ref object
  header: seq[string]
  data: string
  lineEnd: string
  separator: string
  quote: char

proc dumpHook(p: PrintContext, v: string) =
  var needsQuote = false
  for c in v:
    if c in {' ', '\t', '\n', '\r', '\\', ',', '\'', '"'}:
      needsQuote = true
      break
  if needsQuote:
    p.data.add p.quote
    for c in v:
      case c:
      of '\\': p.data.add r"\\"
      of '\b': p.data.add r"\b"
      of '\f': p.data.add r"\f"
      of '\n': p.data.add r"\n"
      of '\r': p.data.add r"\r"
      of '\t': p.data.add r"\t"
      of '"': p.data.add r"\"""
      of '\'': p.data.add r"\'"
      else:
        p.data.add c
    p.data.add p.quote
  else:
    p.data.add v

proc dumpHook[T](p: PrintContext, v: T) =
  p.data.add $v

proc toCsv*[T](
  data: seq[T],
  header = newSeq[string](),
  hasHeader = true,
  lineEnd = "\n",
  separator = ",",
  quote = '"'
): string =
  ## Writes out data seq as a CSV.
  ## * header - use this header to write fields in specific order.
  ## * hasHeader - should header row be written.
  var p = PrintContext()
  p.header = header
  p.lineEnd = lineEnd
  p.separator = separator
  p.quote = quote

  if p.header.len == 0:
    for name, field in T().fieldPairs:
      p.header.add(name)

  if hasHeader:
    for name in p.header:
      p.dumpHook(name)
      p.data.add p.separator
    p.data.removeSuffix(p.separator)
    p.data.add(p.lineEnd)

  doAssert p.header.len != 0

  for row in data:
    for headerName in p.header:
      var found = false
      for name, field in row.fieldPairs:
        if headerName == name:
          p.dumpHook(field)
          p.data.add p.separator
          found = true
          break
      if not found:
        p.data.add p.separator

    p.data.removeSuffix(p.separator)
    p.data.add(p.lineEnd)

  return p.data
