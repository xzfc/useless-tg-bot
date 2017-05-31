import unicode
import sequtils
import random

proc runes0(f: string): seq[Rune] =
  toRunes(f)

proc runes0(f: Slice[string]): seq[Rune] =
  result = @[]
  for i in f.a.runeAt(0).int32 .. f.b.runeAt(0).int32:
    result.add Rune(i)

proc runes(a: varargs[seq[Rune], runes0]): seq[Rune] =
  result = @[]
  for i in a:
    for j in i:
      result.add j

proc choice[T](a: seq[T]): T =
  a[a.len.random]

const emojis = @[
  runes("🐀" .. "🐿"),
  runes("😸" .. "🙀"),
  runes("😀" .. "😷"),
  runes("💓" .. "💟", "♥❤🖤"),
]

proc randomEmoji*: string =
  emojis.choice.choice.toUTF8
