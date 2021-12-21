import tabby, benchy, parsecsv, streams, strutils

# let content = readFile("tests/eng.spell.csv")

# type SpellRow = object
#   filenameId: int
#   offsetSpan: string
#   misspelling: string
#   kind: string
#   correction: string

# var testRows = fromCsv(content, seq[SpellRow])

# timeIt "tabby", 100:
#   var rows = fromCsv(content, seq[SpellRow])
#   keep(rows)
#   doAssert testRows == rows

# timeIt "parsecsv", 100:
#   var
#     rows: seq[SpellRow]
#     strm = newStringStream(content)
#     p: CsvParser
#   p.open(strm, "tmp.csv")
#   p.readHeaderRow()
#   while p.readRow():
#     rows.add SpellRow(
#       filenameId: parseInt(p.row[0]),
#       offsetSpan: p.row[1],
#       misspelling: p.row[2],
#       kind: p.row[3],
#       correction: p.row[4]
#     )
#   p.close()
#   keep(rows)
#   doAssert testRows == rows

block:
  let content = readFile("tests/eng.freq.csv")

  type FreqRow = object
    word: string
    count: int

  var testRows = fromCsvFast(content, seq[FreqRow])

  timeIt "tabby", 100:
    var rows = fromCsvFast(content, seq[FreqRow])
    keep(rows)
    doAssert testRows == rows

  timeIt "parsecsv", 100:
    var
      rows: seq[FreqRow]
      strm = newStringStream(content)
      p: CsvParser
    p.open(strm, "tmp.csv")
    p.readHeaderRow()
    while p.readRow():
      rows.add FreqRow(
        word: p.row[0],
        count: parseInt(p.row[1])
      )
    p.close()
    keep(rows)
    doAssert testRows == rows
