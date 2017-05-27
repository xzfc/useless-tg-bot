import ../bot
import ../db
import ../telega/req
import ../telega/html
import ../telega/types
import ../sweet_options
import asyncdispatch
import options
import nre

let re_reply = re r"""(*UTF8)(?x)(?s)
  \/[@a-zA-Z_]+
  \ +
  (?<text> .* )
  $
"""

proc process0(bot: Bot, update: Update): Option[(Message, string)] =
  update.message ?-> message:
    message.text ?-> text:
      message.entities ?-> entities:
        let html = render_entities(text, entities)
        html.match(reReply) ?-> match:
          message.reply_to_message ?-> originalMessage:
            return some((originalMessage, match.captures["text"]))

proc process*(bot: Bot, update: Update) {.async.} =
  if update.isCommand(bot, "reply"):
    process0(bot, update) ?-> val:
      asyncCheck bot.tg.reply(val[0], val[1], parseMode="HTML")
    else:
      update.message ?-> message:
        asyncCheck bot.tg.reply(message, "...")
