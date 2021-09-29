import tabby, benchy, parsecsv, streams, strutils

let content = readFile("tests/eng.spell.csv")

type SpellRow = object
  filenameId: int
  offsetSpan: string
  misspelling: string
  kind: string
  correction: string

timeIt "tabby", 100:
  var rows = formCSV(content, seq[SpellRow])
  keep(rows)

timeIt "parsecsv", 100:
  var
    rows: seq[SpellRow]
    strm = newStringStream(content)
    p: CsvParser
  p.open(strm, "tmp.csv")
  p.readHeaderRow()
  while p.readRow():
    for col in items(p.headers):
      rows.add SpellRow(
        filenameId: parseInt(p.row[0]),
        offsetSpan: p.row[1],
        misspelling: p.row[2],
        kind: p.row[3],
        correction: p.row[4]
      )
  p.close()

  keep(rows)
