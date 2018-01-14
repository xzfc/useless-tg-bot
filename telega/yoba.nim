import nre
import ../db
import ../sweet_options
import tables
import asyncdispatch
import strutils
import sets
import ../bot
import ./types
import ./req

let reTextMention = re r"""(*UTF8)(?x)
  <a\ href="tg://user\?id=(?<id>[0-9]+)">
    (?<text> .*? )
  </a>
"""

var buzzers : seq[int64]
var buzzerIter = 0
proc nextBuzzer(): int64 =
  if buzzerIter >= buzzers.len:
    buzzerIter = 0
  result = buzzers[buzzerIter]
  inc buzzerIter

proc replyWithTextMentions*(bot: Bot,
                            message: Message,
                            text: string,
                            deletable: bool,
                           ): Future[void] {.async.} =
  # 1) Send message without text mentions.
  # 2) Probe all mentioned users using buzzers.
  # 3) Edit message adding mentions.
  # 4) If `deletable`, mark sent message as deletable

  let empty = text.replace(reTextMention) do (m: RegexMatch) -> string:
    m.captures["text"]

  let reply = bot.tg.reply(message, empty, parseMode="HTML",
                           disableWebPagePreview=true)

  var ids    = initOrderedSet[int32]()
  var ok     = initOrderedSet[int32]()
  var checks = initTable[int32, Future[Option[Message]]]()

  for i in text.findIter(reTextMention):
    ids.incl i.captures["id"].parseInt.int32

  buzzers = db.getBuzzers(bot.db)
  for id in ids:
    checks[id] = bot.tg.sendMessage(
      nextBuzzer(),
      "<a href=\"tg://user?id=" & $id & "\">.</a>",
      parseMode="HTML")

  for id in ids:
    let reply = await checks[id]
    if reply.isSome:
      ok.incl id
  let new_msg = text.replace(reTextMention) do (m: RegexMatch) -> string:
    let id = m.captures["id"].parseInt.int32
    if ok.contains id:
      m.match
    else:
      m.captures["text"]

  let replyStatus = await reply
  replyStatus ?-> reply:
    if deletable:
      bot.db.rememberDeletable(reply.chat.id, reply.message_id)
    asyncCheck bot.tg.editMessageText(reply.chat.id,
                                      reply.message_id,
                                      new_msg,
                                      parseMode="html")
