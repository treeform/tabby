import critbits, tabby, print, strutils, algorithm, tables

var spelling: CritBitTree[string]

type SpellRow = object
  filenameId: int
  offsetSpan: string
  misspelling: string
  kind: string
  correction: string
var spellRows = tabby.formCSV($readFile("eng.spell.csv"), seq[SpellRow])
for s in spellRows:
  spelling[s.misspelling] = s.correction

var scores: CritBitTree[int]

type FreqRow = object
  word: string
  count: int
var freqRows = tabby.formCSV($readFile("eng.freq.csv"), seq[FreqRow])
for s in freqRows:
  scores[s.word] = s.count

proc suggestions(prefix: string): seq[string] =
  var best: CountTable[string]
  for key, score in scores.pairsWithPrefix(prefix):
    best[key] = score

  for bad, good in spelling.pairsWithPrefix(prefix):
    best[good] = scores[good]

  best.sort()

  var i = 0
  for k, b in best:
    if i >= 10:
      break
    result.add(k)
    inc i

echo suggestions("carr")
echo suggestions("managery")
echo suggestions("dja")
echo suggestions("yi")
