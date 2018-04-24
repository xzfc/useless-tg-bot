import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
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
  asyncCheck bot.tg.sendMessage(
    chat_id=message.chat.id,
    text=html.match(reReply).get.captures["text"],
    parseMode="HTML",
    replyToMessageId=message.replyToMessage.toOption.map(a => a.message_id))
