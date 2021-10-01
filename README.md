# Tabby - Direct to object CSV/TSV/tabulated data parser with hooks.

`nimble install tabby`

![Github Actions](https://github.com/treeform/tabby/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/treeform/tabby)

This library has no dependencies other than the Nim standard libarary.

## About

This library is still in development and is not ready to be used.

This library parses `.csv` files directly into nim objects. This is different from how Nim's standard library [parsecsv](https://nim-lang.org/docs/parsecsv.html) works which first parses them into an intermediate representation. This make `tabby` faster by generating less memory allocations.

Tabby is also simpler API and is easier to use with just two calls `fromCsv()/toCsv()`. Its trivial to convert your data to and from tabluar format.

This is similar to my other [jsony](https://github.com/treeform/jsony) project that is for `json`, except this `.csv` files.

## Speed

Because tabby does not allocate intermediate objects is much faster and a lot less code.

```
name ............................... min time      avg time    std dv   runs
tabby .............................. 2.164 ms      2.220 ms    ±0.118   x100
parsecsv ........................... 2.949 ms      2.971 ms    ±0.019   x100
```

## How to use

You need to have csv data:
```
word,count
the,23135851162
of,13151942776
and,12997637966
```
And a nim object that has the correct schema:
```nim
  type FreqRow = object
    word: string
    count: int
```

Then simply read in the data:
```nim
  var rows = tabby.fromCsv(csvData, seq[FreqRow])
```
