# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ./req
import ./types
import asyncdispatch
import future
import nre
import sets
import strutils
import tables

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
                            dropMentsions: bool,
                           ): Future[Option[Message]] {.async.} =
  # 1) Send message without text mentions.
  # 2) Probe all mentioned users using buzzers.
  # 3) Edit message adding mentions.
  # 4) If `deletable`, mark sent message as deletable

  let empty = text.replace(reTextMention) do (m: RegexMatch) -> string:
    m.captures["text"]

  let reply = bot.tg.reply(message, empty, parseMode="HTML",
                           disableWebPagePreview=true)

  if dropMentsions:
    return await reply

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
  result = replyStatus
  replyStatus ?-> reply:
    if new_msg != empty:
      let editRes = await bot.tg.editMessageText(reply.chat.id,
                                                 reply.message_id,
                                                 new_msg,
                                                 parseMode="HTML")
      if editRes.isSome:
        result = editRes

proc markDeleteable*(msg: Future[Option[Message]],
                     bot: Bot,
                     user: Option[User] = User.none
                    ): Future[void] {.async.} =
  (await msg) ?-> m:
    bot.db.rememberDeletable(m.chat.id, m.message_id, user.map(u=>u.id))
