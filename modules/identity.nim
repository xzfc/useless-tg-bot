# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import ../texts
import ./ids
import asyncdispatch
import options
import sequtils
import strutils

MODULE()

proc htmlEscape(s: string): string =
  result = newStringOfCap s.len
  for c in s.items:
    case c
    of '<': result.add "&lt;"
    of '>': result.add "&gt;"
    of '&': result.add "&amp;"
    else:   result.add c

proc getTarget(message: Message): Option[User] =
  let targetMessage = if message.replyToMessage.isNil:
      message
    else:
      message.replyToMessage[]
  return targetMessage.forwardFrom //
         targetMessage.leftChatMember //
         targetMessage.fromUser

proc listNames(names: seq[string], prepend: string): string =
  proc item(s: string): string =
    "  " & prepend & s
  names.map(item).join("\n").htmlEscape

proc process(bot: Bot, update: Update) {.async.} =
  if not update.isCommand(bot, "identity"):
    return
  let message = update.message.get
  block:
    let target = message.getTarget.getOrBreak
    let history = db.searchUserHistory(bot.db, target.id)
    let text = texts.identity % @[
        $target.id,
        target.fullName.htmlEscape,
        history.fullName.listNames "",
        history.uname.listNames "@"]
    asyncCheck bot.tg.reply(message, text, parseMode="HTML")
