import ./randomEmoji
import random
import sequtils
import strutils
import unicode

proc weighedChoice[T](s: seq[(int, T)]): T =
  var score = foldl(s, a + b[0], 0).random
  for c in s:
    score -= c[0]
    if score < 0:
      return c[1]

proc gen1(): string =
  @[
    @[(5, "фу"), (1, "фру")].weighedChoice,
    @[(5, ""), (1, "т")].weighedChoice,
    @[(1, ""), (5, "тян"), (1, "нян")].weighedChoice,
    @[(5, ""), (5, "о"), (5, "я"), (2, "очка")].weighedChoice,
    @[(50, ""), (20, "-нян"), (1, "-нян-нян"), (20, "-сама")].weighedChoice,
   ].join()

proc gen1ok(s: string): bool =
  s != "фу" and not s.contains("уо") and not s.contains("уя")

proc gen2(): string =
  result = gen1()
  while not gen1ok(result):
    result = gen1()

proc gen3(): string =
  proc spacedCapsbold(s: string): string =
    "<b>" & unicode.toUpper(s).toRunes().map(toUTF8).join(" ") & "</b>"
  @[(5, unicode.capitalize),
    (2, proc(s:string):string = unicode.toUpper s),
    (1, spacedCapsbold)].weighedChoice()(gen2())

proc gen4(): string =
  let s = gen3()
  if 10.random > 8:
    let e = randomEmoji()
    e & s & e
  else:
    s

proc randomFuto*(): string =
  gen4()

when isMainModule:
  randomize()
  for i in 1..10:
    echo randomFuto()
