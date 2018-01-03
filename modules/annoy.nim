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
      let futoName = randomFuto()
      var msg : string
      var replyTo : int
      bot.db.getLastUserMessage(message.chat.id, 194630356) ?-> lastFutoMessage:
        msg = futoName
        # replyTo = lastFutoMessage # Not now
        replyTo = message.messageId
      else:
        msg = "Я не видела тут " & futoName & "."
        replyTo = message.messageId
      asyncCheck bot.tg.sendMessage(message.chat.id,
                                    msg,
                                    replyToMessageId=replyTo,
                                    parseMode="HTML")
