import ../bot
import ../db
import ../sweet_options
import ../telega/req
import ../telega/types
import ../utils/randomFuto
import asyncdispatch

proc process*(bot: Bot, update: Update) {.async.} =
  if update.isCommand(bot, "futo"):
    update.message ?-> message:
      bot.db.getLastUserMessage(message.chat.id, 194630356) ?-> lastFutoMessage:
        asyncCheck bot.tg.sendMessage(message.chat.id,
                                      randomFuto(),
                                      replyToMessageId=lastFutoMessage,
                                      parseMode="HTML")
