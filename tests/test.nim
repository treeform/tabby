## Put your tests here.

import tabby, strutils

block:
  let csvData = """word,count
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
the,23135851162
of,13151942776
and,12997637966
"""

  type FreqRow = object
    word: string
    count: int

  var rows = tabby.fromCsv(csvData, seq[FreqRow], skipHeader = true)
  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv(skipHeader = true) == csvData

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

  var rows = tabby.fromCsv(csvData, seq[FreqRow], useTab = true)
  doAssert rows.len == 3
  doAssert rows[0].word == "the"
  doAssert rows[0].count == 23135851162
  doAssert rows[1].word == "of"
  doAssert rows[1].count == 13151942776
  doAssert rows[2].word == "and"
  doAssert rows[2].count == 12997637966

  doAssert rows.toCsv(useTab = true) == csvData
