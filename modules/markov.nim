import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import ../utils/randomEmoji
import asyncdispatch
import db_sqlite
import nre
import options
import random
import sequtils
import strutils
import unicode

MODULE()

let reQuestion = re r"""(*UTF8)(?x)(?i)
  ! \ *
  (я|мы|он|она|они|мне|ему|ей|им)
  ,?
  \ +
  (?: [^.] | \.[^ ] )+ # anything except ". "
  \?
  $
"""

proc tokens(text: string): seq[string] =
  text.split(re(r"\s+")).filter(proc(x:string):bool= x.len != 0)

iterator pairs[T](items: seq[T], none:T = nil): (T, T) =
  var prev:T = none
  for i in items:
    yield (prev, i)
    prev = i
  if items.len != 0:
    yield (prev, none)

proc learn(bot: Bot, chatId: int64, text: string) =
  for a, b in text.tokens.pairs:
    bot.db.rememberMarkov(chatId, a, b)


proc generateNext(db: DbConn, chatId: int64, wordFrom: string): string =
  let rows = db.markovGetNext(chatId, wordFrom)
  if rows.len == 0:
    return nil
  else:
    let max = foldl(rows, a + b.count.int, 0)
    if max == 0:
      return nil
    var score = max.random
    for row in rows:
      score -= row.count.int
      if score < 0:
        return row.word

proc generatePhrase(db: DbConn, chatId: int64, start: string, maxLen: int
                   ): string =
  result = ""
  var n = 0
  var word = start
  while not word.isNil and n <= maxLen:
    word = db.generateNext(chatId, word)
    if not word.isNil:
      if result.len != 0:
        result.add " "
      result.add word
    inc n

proc process(bot: Bot, update: Update) {.async.} =
  update.message ?-> message:
    message.text ?-> text:
      if not text.startsWith("/"):
        bot.learn(message.chat.id, text)
      text.match(reQuestion) ?-> match:
        var start: string = "Ты"
        case unicode.toLower(match.captures[0]):
          of "я":   start = "Ты"
          of "мы":  start = "Вы"
          of "он":  start = "Он"
          of "она": start = "Она"
          of "они": start = "Они"
          of "мне": start = "Тебе"
          of "ему": start = "Ему"
          of "ей":  start = "Ей"
          of "им":  start = "Им"
        let replyText = bot.db.generatePhrase(message.chat.id, start, 20)
        if replyText.len != 0:
          asyncCheck bot.tg.reply(message,
                                  start & " " & replyText & " " & randomEmoji())
