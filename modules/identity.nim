import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import ../texts
import ./ids
import asyncdispatch
import options
import sequtils
import strutils

MODULE()

proc htmlEscape(s: string): string =
  result = newStringOfCap s.len
  for c in s.items:
    case c
    of '<': result.add "&lt;"
    of '>': result.add "&gt;"
    of '&': result.add "&amp;"
    else:   result.add c

proc getTarget(message: Message): Option[int32] =
  let targetMessage = if message.replyToMessage.isNil:
      message
    else:
      message.replyToMessage[]
  let user = targetMessage.forwardFrom //
             targetMessage.leftChatMember //
             targetMessage.fromUser
  user ?-> user:
    user.id.some
  else:
    int32.none

proc listNames(names: seq[string], prepend: string): string =
  proc item(s: string): string =
    "  " & prepend & s
  names.map(item).join("\n").htmlEscape

proc process(bot: Bot, update: Update) {.async.} =
  if not update.isCommand(bot, "identity"):
    return
  let message = update.message.get
  block:
    let targetUid = message.getTarget.getOrBreak
    let history = db.searchUserHistory(bot.db, targetUid)
    let text = texts.identity % @[
        $targetUid,
        history.fullName.listNames "",
        history.uname.listNames "@"]
    asyncCheck bot.tg.reply(message, text, parseMode="HTML")
