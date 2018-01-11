import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import asyncdispatch
import nre
import options

let reReply = re r"""(*UTF8)(?x)(?s)
  \/[@a-zA-Z_]+
  \ +
  (?<text> .* )
  $
"""

proc process*(bot: Bot, update: Update) {.async.} =
  if not update.isCommand(bot, "reply"):
    return
  block:
    let message = update.message.getOrBreak
    let html = renderEntities(message.text.getOrBreak,
                              message.entities.getOrBreak)
    asyncCheck bot.tg.reply(message.replyToMessage.getOrBreak,
                            html.match(reReply).getOrBreak.captures["text"],
                            parseMode="HTML")
    return
  block:
    asyncCheck bot.tg.reply(update.message.getOrBreak, "...")
