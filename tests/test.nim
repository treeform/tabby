## Put your tests here.

import tabby, strutils

block:
  # Most basic parse.
  let csvData = """
word,count
the,23135851162
of,13151942776
and,12997637966
"""

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(csvData, seq[FreqRow])

  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv() == csvData

block:
  # Object field layout does not match header layout.
  let csvData = """
word,count
the,23135851162
of,13151942776
and,12997637966
"""

  type FreqRow = object
    count: int
    extra: bool
    word: string

  var rows = tabby.fromCsv(csvData, seq[FreqRow])
  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv(header = @["word", "count"]) == csvData


block:
  # No header given, figure it out from object layout.
  let csvData = """
the,23135851162
of,13151942776
and,12997637966
"""

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(csvData, seq[FreqRow], hasHeader = false)
  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv(hasHeader = false) == csvData

block:
  # Read header but use your own.
  let csvData = """
w_o_r_d,c_o_u_n_t
the,23135851162
of,13151942776
and,12997637966
"""

  type FreqRow = object
    count: int
    extra: bool
    word: string

  var rows = tabby.fromCsv(csvData, seq[FreqRow], header = @["word", "count"])

  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert "w_o_r_d,c_o_u_n_t\n" & rows.toCsv(
    header = @["word", "count"], hasHeader = false) == csvData


block:
  # Use tab instead of comma.
  let csvData = """
word<tab>count
the<tab>23135851162
of<tab>13151942776
and<tab>12997637966
""".replace("<tab>", "\t")

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(
    csvData, seq[FreqRow], hasHeader = true, separator = "\t"
  )
  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv(separator = "\t") == csvData

block:
  # Parse "quoted" strings.
  let csvData = """
"the apple",1
"of,time",2
"and\nthat",3
"\"bye\"",4
"""

  type TextRow = object
    text: string
    count: int

  var rows = tabby.fromCsv(csvData, seq[TextRow], hasHeader = false)
  doAssert rows.len == 4
  doAssert rows[0].text == "the apple"
  doAssert rows[0].count == 1
  doAssert rows[1].text == "of,time"
  doAssert rows[1].count == 2
  doAssert rows[2].text == "and\nthat"
  doAssert rows[2].count == 3
  doAssert rows[3].text == "\"bye\""
  doAssert rows[3].count == 4

  doAssert rows.toCsv(hasHeader = false) == csvData

block:
  # Parse 'quoted' strings.
  let csvData = """
'the apple',1
'of,time',2
'and\nthat',3
'\"bye\"',4
"""

  type TextRow = object
    text: string
    count: int

  var rows = tabby.fromCsv(csvData, seq[TextRow], hasHeader = false)
  doAssert rows.len == 4
  doAssert rows[0].text == "the apple"
  doAssert rows[0].count == 1
  doAssert rows[1].text == "of,time"
  doAssert rows[1].count == 2
  doAssert rows[2].text == "and\nthat"
  doAssert rows[2].count == 3
  doAssert rows[3].text == "\"bye\""
  doAssert rows[3].count == 4

  #doAssert rows.toCsv(hasHeader = false, quote='\'') == csvData

block:
  # Prase windows line endings.
  let csvData = "word\tcount\r\nthe\t23135851162\r\n"

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(
    csvData, seq[FreqRow], hasHeader = true, separator = "\t", lineEnd = "\r\n"
  )
  doAssert rows.len == 1
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162

  doAssert rows.toCsv(separator = "\t", lineEnd = "\r\n") == csvData


block:
  # Prase crazy separator and crazy line endings.
  let csvData = "word:~:count-->the:~:23135851162-->"

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(
    csvData, seq[FreqRow], hasHeader = true, separator = ":~:", lineEnd = "-->"
  )
  doAssert rows.len == 1
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162

  doAssert rows.toCsv(separator = ":~:", lineEnd = "-->") == csvData

block:
  # Crazy spaces between tokens.
  let csvData = "  word :~: count-->    the :~: 23135851162     -->"

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(
    csvData, seq[FreqRow], hasHeader = true, separator = ":~:", lineEnd = "-->"
  )
  doAssert rows.len == 1
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162


block:
  # Missing last new line.
  let csvData = "word\tcount\r\nthe\t23135851162"

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(
    csvData, seq[FreqRow], hasHeader = true, separator = "\t", lineEnd = "\r\n"
  )
  doAssert rows.len == 1
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162


block:
  # Guess sep and newline
  let csvDatas = @[
    "word,count\nthe,23135851162\n",
    "word\tcount\nthe\t23135851162\n",
    "word,count\r\nthe,23135851162\r\n",
    "word\tcount\r\nthe\t23135851162\r\n"
  ]

  type FreqRow = object
    word: string
    count: int

  for csvData in csvDatas:
    var rows = tabby.fromCsvGuess(csvData, seq[FreqRow])
    doAssert rows.len == 1
    doAssert rows[0].word == "the"
    doAssert rows[0].count == 23135851162



# Prase and dump hooks

let csvData = """
country,budget
US,$2000
GB,$1000
DE,$1000
"""

type
  Money = uint64 # in cents

  CountryMoney = object
    country: string
    budget: Money

proc parseHook(p: ParseContext, v: var Money) =
  inc p.i # skip the $
  var num: int
  p.parseHook(num)
  v = num.uint64 * 100 # in cents

var rows = csvData.fromCsv(seq[CountryMoney])

proc dumpHook(p: DumpContext, v: Money) =
  # read teh %
  p.data.add "$"
  p.data.add $(v div 100)

echo rows.toCsv()
doAssert rows.toCsv() == """
country,budget
US,$2000
GB,$1000
DE,$1000
"""


block:
  # One time to read two different formats:

  type Row = object
    id: int
    color: string
    date: string
    text: string
    enabled: bool

  let csvData = """
date,text
Mar1,foo
Mar2,bar
Mar3,baz
"""
  echo csvData.fromCsv(seq[Row])

  let csvData2 = """
id,color,date,text,enabled
0,red,Mar1,foo,true
1,blue,Mar2,bar,false
2,green,Mar3,baz,true
"""
  echo csvData2.fromCsv(seq[Row])

block:
  # Duplicate names.

  type Row = object
    id: int
    date1: string
    text1: string
    date2: string
    text2: string

  let csvData = """
date,text
Mar1,foo
Mar2,bar
Mar3,baz
"""
  echo csvData.fromCsv(seq[Row], header = @["date1", "text1"])

  let csvData2 = """
iden,date,text,date,text
0,Mar1,foo,Dec20,dasher
1,Mar2,bar,Dec21,dancer
2,Mar3,baz,Dec22,prancer
"""
  echo csvData2.fromCsv(seq[Row], header = @["id", "date1", "text1", "date2", "text2"])
