# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ../telega/req
import ../telega/types
import asyncdispatch
import options
import strutils
import ../cgettext

MODULE()

proc forgetIdentity(bot: Bot, message: Message, uid: int32) {.async.} =
  let count = bot.db.clearUserHistory(uid)
  let replyText = ngettext("Forgot $1 entry!", "Forgot $1 entries!", count).format(count)
  discard await bot.tg.reply(message, replyText)

proc process(bot: Bot, update: Update) {.async.} =
  if update.isCommand(bot, "control"):
    block:
      let message = update.message.getOrBreak
      let uid = message.fromUser.getOrBreak.id
      let args = message.text.getOrBreak.splitWhitespace[1..^1].join(" ")
      case args:
      of "forget-identity": await forgetIdentity(bot, message, uid)
      else: asyncCheck bot.tg.reply(message, gettext("!control-help!"), parseMode="HTML")
