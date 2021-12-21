# Fast direct CSV/TCV parser for nim.
import strutils, parseutils, strformat

type TabbyError* = object of ValueError

type ParseContext = ref object
  i: int
  header: seq[string]
  data: string
  newLine: string
  sep: char

template error(msg: string, i: int) =
  ## Shortcut to raise an exception.
  raise newException(TabbyError, msg & " At offset: " & $i)

proc atNewLine(p: ParseContext): bool =
  ## Tests if the parser context is at a new line.
  return p.data[p.i] != '\n'

proc skipLine(p: ParseContext) =
  ## Skips this line.
  let at = p.data.find(p.newLine, p.i)
  if at != -1:
    p.i = at + p.newLine.len

proc skipSpaces(p: ParseContext) =
  ## Skips spaces to next token.
  while p.i < p.data.len and p.data[p.i] == ' ':
    inc p.i

proc skipSep(p: ParseContext) =
  ## Skips current separator.
  if p.i < p.data.len and p.data[p.i] == '\n':
    return
  elif p.i < p.data.len and p.data[p.i] == p.sep:
    inc p.i
  else:
    error(&"Failed to parse, separator expected, got: {p.data[p.i]}.", p.i)

proc parseHook(p: ParseContext, v: var string) =
  ## Parse hook for string.
  p.skipSpaces()
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
    while p.i < p.data.len and p.data[p.i] notin {p.sep, '\n'}:
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
  useTab = false
): seq[T] =
  ## Read un data seq as a CSV.
  ## * header - use this header to parse
  ## * hasHeader - does the current data have a header,
  ##   will be skipped if header is set.
  ## * useTab - use tabs instead of commas.
  var p = ParseContext()
  p.data = data
  p.header = header
  var userHeader = header.len != 0
  p.newLine = "\n"
  p.sep = ','
  if useTab:
    p.sep = '\t'

  if hasHeader:
    while p.atNewLine():
      var name: string
      p.parseHook(name)
      if not userHeader:
        p.header.add(name)
      p.skipSep()
    p.skipLine()
  else:
    if not userHeader:
      for name, field in T().fieldPairs:
        p.header.add(name)

  while p.i < p.data.len:
    var currentRow = T()
    for headerName in p.header:
      for name, field in currentRow.fieldPairs:
        if headerName == name:
          parseHook(p, field)
          p.skipSep()
    result.add(currentRow)
    p.skipLine()

proc dumpHook(s: var string, v: string) =
  var needsQuote = false
  for c in v:
    if c in {' ', '\t', '\n', '\r', '\\', ',', '\'', '"'}:
      needsQuote = true
      break
  if needsQuote:
    s.add '"'
    for c in v:
      case c:
      of '\\': s.add r"\\"
      of '\b': s.add r"\b"
      of '\f': s.add r"\f"
      of '\n': s.add r"\n"
      of '\r': s.add r"\r"
      of '\t': s.add r"\t"
      of '"': s.add r"\"""
      else:
        s.add c
    s.add '"'
  else:
    s.add v

proc dumpHook[T](s: var string, v: T) =
  s.add $v

proc toCsv*[T](
  data: seq[T],
  header = newSeq[string](),
  hasHeader = true,
  useTab = false,
): string =
  ## Writes out data seq as a CSV.
  ## * header - use this header to write fields in specific order.
  ## * hasHeader - should header row be written.
  var separator = ","
  if useTab:
    separator = "\t"

  var header = header
  if header.len == 0:
    for name, field in T().fieldPairs:
      header.add(name)

  if hasHeader:
    for name in header:
      result.dumpHook(name)
      result.add separator
    result.removeSuffix(separator)
    result.add("\n")

  for row in data:
    for headerName in header:
      var found = false
      for name, field in row.fieldPairs:
        if headerName == name:
          result.dumpHook(field)
          result.add separator
          found = true
          break
      if not found:
        result.add separator

    result.removeSuffix(separator)
    result.add("\n")
