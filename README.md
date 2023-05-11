# Tabby - Fast CSV parser with hooks.

`nimble install tabby`

![Github Actions](https://github.com/treeform/tabby/workflows/Github%20Actions/badge.svg)

[API reference](https://treeform.github.io/tabby)

This library has no dependencies other than the Nim standard library.

## About

This library parses `.csv` or `.tsv` files directly into Nim objects. This is different from how Nim's standard library [parsecsv](https://nim-lang.org/docs/parsecsv.html) works which first parses them into an intermediate representation. This makes `tabby` generate fewer memory allocations.

Tabby also has a simpler API and is easier to use with just two calls `fromCsv`/`toCsv`:
```nim
let rows = strData.fromCsv(seq[RowObj])
```
and back:
```nim
echo rows.toCsv()
```

Tabby also supports arbitrary delimiters. Not only standard tab `\t` and `,` with linux `\n` and windows `\r\n` line endings, but any delimiter can be used. It's trivial to convert your data to and from any tabular format:
```nim
strData.fromCsv(seq[RowObj], separator = ":", lineEnd = ";")
```

Tabby can also guess delimiters with `fromCsvGuess()` function.

This library is similar to my other [jsony](https://github.com/treeform/jsony) project that is for `json`, if you like `jsony` you should like `tabby`.


## How to use

You need to have CSV strData:
```
word,count
the,23135851162
of,13151942776
and,12997637966
```
And a regular Nim object to parse into to:
```nim
type FreqRow = object
  word: string
  count: int
```

Then simply read in the data:

```nim
var rows = strData.fromCsv(seq[FreqRow])
```

Compare this single line with confusing but equivalent `std/parcecsv` code:

```nim
var
  rows: seq[FreqRow]
  strm = newStringStream(content)
  p: CsvParser
p.open(strm, "tmp.csv")
p.readHeaderRow()
while p.readRow():
  rows.add FreqRow(word: p.row[0], count: parseInt(p.row[1]))
p.close()
```

## Speed

Even though tabby does not allocate intermediate objects, it does use header and field re-ordering, and parse and dump hooks, which makes makes it speed close to `std/parcecsv` but with much simpler API.

```
name ............................... min time      avg time    std dv   runs
tabby ............................ 134.951 ms    141.897 ms    ±7.301   x100
parsecsv ......................... 129.861 ms    136.086 ms    ±7.026   x100
```

## Parse Hooks

Sometimes the data you get from a csv file is not quite in the format you are looking for. You can define your own `parseHook` function to parse any data.

```nim
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
```

## Dump Hooks

Just like with parse hooks, sometimes the format you want to write to a csv file is not quite the format your objects are. You can define your own `dumpHook` function to output your data in any format.

```nim
proc dumpHook(d: DumpContext, v: Money) =
  # read teh %
  d.data.add "$"
  d.data.add $(v div 100)

echo rows.toCsv()
```
