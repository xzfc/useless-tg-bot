# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import ../telega/yoba
import asyncdispatch
import future
import nre
import options

MODULE()

let reReply = re r"""(*UTF8)(?x)(?s)
  \/[@a-zA-Z_]+
  \ +
  (?<text> .* )
  $
"""

proc process(bot: Bot, update: Update) {.async.} =
  if not update.isCommand(bot, "reply"):
    return
  let message = update.message.get
  let html = renderEntities(message.text.get, message.entities.get)
  let replyTo = message.replyToMessage.toOption.map(a => a.message_id)
  html.match(reReply) ?-> m:
    asyncCheck bot.tg.sendMessage(
      chatId = message.chat.id,
      text = m.captures["text"],
      parseMode = "HTML",
      replyToMessageId = replyTo
    ).markDeleteable(bot, message.fromUser)
  else:
    let document = bot.db.getLastUserDocument(
      message.chat.id, message.fromUser.get.id)
    document ?-> document:
      asyncCheck bot.tg.sendSticker(
        chatId = message.chat.id,
        sticker = document,
        replyToMessageId = message.replyToMessage.toOption.map(a => a.message_id)
      ).markDeleteable(bot, message.fromUser)
    else:
      asyncCheck bot.tg.reply(message, "...").markDeleteable(bot)
