import ../bot
import ../db
import ../sweet_options
import ../telega/req
import ../telega/types
import ../utils/lang
import asyncdispatch
import db_sqlite
import future
import nre
import options
import random
import sequtils
import strutils

MODULE()

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

proc mkNext(db: DbConn, chatId: int64): (string -> string) = 
  return proc(wordFrom: string): string =
    generateNext(db, chatId, wordFrom)

proc process(bot: Bot, update: Update) {.async.} =
  block:
    let message = update.message.getOrBreak
    let text = message.text.getOrBreak
    if not text.startsWith("/"):
      bot.learn(message.chat.id, text)
    let text2 = text.matchMention(bot.me.username.getOrBreak).getOrBreak
    let reply = mkReply(text2, mkNext(bot.db, message.chat.id)).getOrBreak
    asyncCheck bot.tg.reply(message, reply)
