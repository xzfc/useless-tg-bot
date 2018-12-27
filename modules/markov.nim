# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ../telega/req
import ../telega/types
import ../utils/lang
import ../utils/markov_lib
import asyncdispatch
import db_sqlite
import nre
import options
import random
import sequtils
import strutils
import sugar

MODULE()

proc process(bot: Bot, update: Update) {.async.} =
  block:
    let message = update.message.getOrBreak
    let text = message.text.getOrBreak
    block:
      let text2 = text.matchMention(bot.me.username.getOrBreak).getOrBreak
      let reply = mkReply(text2, bot.markov, message.chat.id).getOrBreak
      asyncCheck bot.tg.reply(message, reply)
    if not text.startsWith("/"):
      bot.markov.learn(message.chat.id.int, message.messageId.int, text)
