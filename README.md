# Tabby - Direct to object CSV/TSV/tabulated data parser with hooks.

This library parses `.csv` files directly into nim objects. This is different from how Nim's standard library [parsecsv](https://nim-lang.org/docs/parsecsv.html) works which first parses them into an intermediate representation. This make `tabby` faster by generating less memory allocations.

This is similar to my other [jsony](https://github.com/treeform/jsony) project that is for `json`, except this `.csv` files.

## Speed

Because tabby does not allocate intermediate objects is much faster and a lot less code.

```
name ............................... min time      avg time    std dv   runs
tabby .............................. 3.197 ms      3.446 ms    ±0.223   x100
parsecsv .......................... 14.809 ms     15.491 ms    ±0.812   x100
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
  var rows = tabby.formCSV(csvData, seq[FreqRow])
```
