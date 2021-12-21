## Put your tests here.

import tabby, strutils

block:
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
    csvData, seq[FreqRow], hasHeader = true, useTab = true
  )
  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv(useTab = true) == csvData

block:
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
