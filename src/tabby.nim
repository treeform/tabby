# Fast direct CSV/TCV parser for nim.
import strutils, parseutils, strformat

type TabbyError* = object of ValueError

type ParseContext* = ref object
  i*: int
  header*: seq[string]
  data*: string
  lineEnd*: string
  separator*: string

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

proc parseHook*(p: ParseContext, v: var string) =
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

proc parseHook*(p: ParseContext, v: var SomeInteger) =
  ## Parse hook for integer.
  var num: int
  let chars = parseutils.parseInt(p.data, num, p.i)
  if chars == 0:
    error("Failed to parse a integer.", p.i)
  p.i += chars
  v = num

proc parseHook*(p: ParseContext, v: var bool) =
  ## Parse hook for boolean.
  var str: string
  p.parseHook(str)
  v = str.toLowerAscii() == "true"

proc fromCsvFast*[T](
  data: string,
  objType: type[seq[T]],
  hasHeader = true,
  lineEnd = "\n",
  separator = ","
): seq[T] =
  ## Read data seq as a CSV.
  ## Objects schema must match CSV schema.
  ## * hasHeader - should header be skipped.
  ##   will be skipped if header is set.
  var p = ParseContext()
  p.data = data
  p.lineEnd = lineEnd
  p.separator = separator

  if hasHeader:
    p.skipLine()

  while p.i < p.data.len:
    var currentRow = T()
    for name, field in currentRow.fieldPairs:
      parseHook(p, field)
      if p.i == p.data.len:
        result.add(currentRow)
        return
      p.skipSep()
    result.add(currentRow)
    p.skipLine()

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

proc fromCsvGuess*[T](
  data: string,
  objType: type[seq[T]],
  header = newSeq[string](),
  hasHeader = true,
): seq[T] =
  ## Read data seq as a CSV.
  ## Tries to guess what separators or lineEnds are used.

  var separator = ","
  if data.count("\t") > data.count(","):
    separator = "\t"
  var lineEnd = "\n"
  if data.count("\r\n") > data.count("\n") div 2:
    lineEnd = "\r\n"

  return data.fromCsv(objType, header, hasHeader, lineEnd, separator)

type DumpContext* = ref object
  header*: seq[string]
  data*: string
  lineEnd*: string
  separator*: string
  quote*: char

proc dumpHook*(d: DumpContext, v: string) =
  var needsQuote = false
  for c in v:
    if c in {' ', '\t', '\n', '\r', '\\', ',', '\'', '"'}:
      needsQuote = true
      break
  if needsQuote:
    d.data.add d.quote
    for c in v:
      case c:
      of '\\': d.data.add r"\\"
      of '\b': d.data.add r"\b"
      of '\f': d.data.add r"\f"
      of '\n': d.data.add r"\n"
      of '\r': d.data.add r"\r"
      of '\t': d.data.add r"\t"
      of '"': d.data.add r"\"""
      of '\'': d.data.add r"\'"
      else:
        d.data.add c
    d.data.add d.quote
  else:
    d.data.add v

proc dumpHook*[T](d: DumpContext, v: T) =
  d.data.add $v

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
  var d = DumpContext()
  d.header = header
  d.lineEnd = lineEnd
  d.separator = separator
  d.quote = quote

  if d.header.len == 0:
    for name, field in T().fieldPairs:
      d.header.add(name)

  if hasHeader:
    for name in d.header:
      d.dumpHook(name)
      d.data.add d.separator
    d.data.removeSuffix(d.separator)
    d.data.add(d.lineEnd)

  doAssert d.header.len != 0

  for row in data:
    for headerName in d.header:
      var found = false
      for name, field in row.fieldPairs:
        if headerName == name:
          d.dumpHook(field)
          d.data.add d.separator
          found = true
          break
      if not found:
        d.data.add d.separator

    d.data.removeSuffix(d.separator)
    d.data.add(d.lineEnd)

  return d.data
