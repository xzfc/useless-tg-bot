import ../sweet_options
import ./markov_lib
import ./randomEmoji
import algorithm
import future
import nre
import random
import sequtils
import strutils except toLower, capitalize
import unicode
import unittest

proc uncapitalize(s: string): string =
  if len(s) == 0:
    s
  else:
    var
      rune: Rune
      i = 0
    fastRuneAt(s, i, rune, doInc=true)
    $toLower(rune) & substr(s, i)

iterator runesIdx(s: string): (Rune, int) =
  var
    i = 0
    result: Rune
  while i < len(s):
    fastRuneAt(s, i, result, true)
    yield (result, i)

const
  pro1per = @[
    "я", "меня", "мне", "меня", "мной", "мною", "мне",
    "мы", "нас", "нам", "нас", "нами", "нас",
  ]

  pro2per = @[
    "ты", "тебя", "тебе", "тебя", "тобой", "тобою", "тебе",
    "вы", "вас", "вам", "вас", "вами", "вас",
  ]

  proRest = @[
    "он", "его", "него", "ему", "нему",
    "она", "её", "неё", "ней", "ей", "ею", "нею",
    "им", "ним", "нём", "они", "их", "них", "ими", "ними",
    "оно",
  ]

proc isPronoun(s: string): bool =
  pro1per.contains(s) or pro2per.contains(s) or proRest.contains(s)

proc reversePersonWord(s: string): string =
  var id: int

  id = pro1per.find(s)
  if id != -1:
    return pro2per[id]

  id = pro2per.find(s)
  if id != -1:
    return pro1per[id]

  return nil

proc split(s: string): (string, string) =
  var okIdx = 0
  for rune, idx in s.runesIdx:
    if not rune.isAlpha:
      return (s[0..okIdx-1], s[okIdx..^0])
    else:
      okIdx = idx
  return (s, "")

proc reversePerson(s: string): string =
  let (first, rest) = s.split
  let reversed = first.toLower.reversePersonWord
  if reversed.isNil:
    s
  else:
    reversed.capitalize & rest

suite "pronouns":
  test "reversePersonWord":
    check reversePersonWord("мне") == "тебе"
    check reversePersonWord("вам") == "нам"
    check reversePersonWord("его") == nil
    check reversePersonWord("мне тебе") == nil

  test "split":
    check split("foo bar") == ("foo", " bar")
    check split("фу бар")  == ("фу", " бар")
    check split("foo—bar") == ("foo", "—bar")
    check split("фу—бар")  == ("фу", "—бар")
    check split("foo")     == ("foo", "")

  test "reversePerson":
    check reversePerson("Мне ...") == "Тебе ..."
    check reversePerson("мне ...") == "Тебе ..."
    check reversePerson("МНЕ ...") == "Тебе ..."
    check reversePerson("Вам ...") == "Нам ..."
    check reversePerson("Его ...") == "Его ..."



let reName = re r"""(*UTF8)(?x)(?i)
    Холи
  | Крекер[сз]?
  | Холи\ +Крекер[сз]?
  | Holy\ +Crackers
"""

proc matchMention*(s, username: string): Option[string] =
  s.match(reName) ?-> match:
    var rest = s[match.matchBounds.b+1..^1]
    if not rest.startsWith(","):
      return
    return rest[1..^1].strip(true, false).some
  let prefix = "@" & username & " "
  if s.startsWith(prefix):
    return s[prefix.len..^1].strip(true, false).some
  return


let reWhether = re r"""(*UTF8)(*UCP)(?x)(?i)
  (?<left> .*? )
  \ +
  ли
  \ +
  (?<right> .* )
  \?
"""

let reOr = re r"""(*UTF8)(*UCP)(?x)(?i)
  (?<left> .*? )
  ,?
  \ +
  или
  \ +
  (?<right> .* )
  \?
"""

proc choice[T](a: seq[T]): T =
  a[a.len.random]

proc generateMarkovPhrase(
    start: string, maxLen: int,
    next: string -> string): string =
  result = ""
  var n = 0
  var word = start
  while not word.isNil and n <= maxLen:
    word = next(word)
    if not word.isNil:
      if result.len != 0:
        result.add " "
      result.add word
    inc n

proc mkReply*(s: string, m: Markov, chatId: int64): Option[string] =
  s.match(reWhether) ?-> match:
    let left = match.captures["left"]
    let right = match.captures["right"]
    const q = @[
      @[" не ", " ни разу не "],
      @[" "],
    ]
    return some(right.reversePerson.capitalize &
                q.choice.choice &
                left.uncapitalize &
                ".")

  s.match(reOr) ?-> match:
    let left = match.captures["left"]
    let right = match.captures["right"]
    let reply = @[left.uncapitalize, right].choice
    return (reply & ".").reversePerson.capitalize.some

  block:
    let text = m.generate(chatId.int, s.reversePerson, 50)
    if text.len != 0:
      return (text.capitalize & " " & randomEmoji()).some

  return randomEmoji().some

suite "regex":
  test "matchMention":
    check matchMention("Холи, ...", "holy") == "...".some
    check matchMention("Холи ...",  "holy").isNone
    check matchMention("@holy ...", "holy") == "...".some
    check matchMention("@holyblabla ...",  "holy").isNone
