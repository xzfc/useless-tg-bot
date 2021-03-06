# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ../telega/req
import ../telega/types
import ../cgettext
import asyncdispatch
import options

# /delete -- request to delete bot's message
# All requirements are mandatory:
# * it's bot's own message
# * message is explicitly marked "deletable" by this or any user in bot DB

MODULE()

proc process(bot: Bot, update: Update) {.async.} =
  if update.isCommand(bot, "delete"):
    block:
      let message = update.message.getOrBreak
      let origMsg = message.reply_to_message.getOrBreak
      if (origMsg.fromUser.?id) != bot.me.id:
        break
      if bot.db.haveDeletable(origMsg.chat.id,
                              origMsg.message_id,
                              message.fromUser.?id):
        asyncCheck bot.tg.deleteMessage(origMsg.chat.id,
                                        origMsg.message_id)
        bot.db.forgetDeletable(origMsg.chat.id, origMsg.message_id)
      else:
        asyncCheck bot.tg.reply(message, pgettext("delete", "nah"))
