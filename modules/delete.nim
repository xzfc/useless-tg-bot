import ../bot
import ../db
import ../sweet_options
import ../telega/req
import ../telega/types
import ../texts
import asyncdispatch
import options

# /delete -- request to delete bot's message
# All requirements are mandatory:
# * it's bot's own message
# * message is explicitly marked "deletable" in bot DB

proc process*(bot: Bot, update: Update) {.async.} =
  if update.isCommand(bot, "delete"):
    block:
      let message = update.message.getOrBreak
      let origMsg = message.reply_to_message.getOrBreak
      if (origMsg.fromUser.?id) != bot.me.id:
        break
      if bot.db.haveDeletable(origMsg.chat.id, origMsg.message_id):
        asyncCheck bot.tg.deleteMessage(origMsg.chat.id,
                                        origMsg.message_id)
        bot.db.forgetDeletable(origMsg.chat.id, origMsg.message_id)
      else:
        asyncCheck bot.tg.reply(message, texts.deleteNo)
