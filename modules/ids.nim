import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/types
import asyncdispatch
import options
import sequtils

proc rememberUsers(bot: Bot, update: Update) =
  proc handleUser(user: User) =
    bot.db.rememberUser user
  proc handleEntity(entity: MessageEntity) =
    if entity.`type` == metTextMention:
      bot.db.rememberUser entity.user
  proc handleMessage(msg: Message) =
    msg.`from`.map         handleUser
    msg.forwardFrom.map    handleUser
    msg.newChatMember.map  handleUser
    msg.leftChatMember.map handleUser
    if msg.entities.isSome:
      for entity in msg.entities.get:
        handleEntity entity
    if not msg.replyToMessage.isNil:
      msg.replyToMessage[].handleMessage
    if not msg.pinnedMessage.isNil:
      msg.pinnedMessage[].handleMessage
  update.message.map           handleMessage
  update.editedMessage.map     handleMessage
  update.channelPost.map       handleMessage
  update.editedChannelPost.map handleMessage

proc rememberLast(bot: Bot, update: Update) =
  block:
    let message = update.message.getOrBreak
    bot.db.rememberLastUserMessage(message.chat.id,
                                   message.`from`.getOrBreak.id,
                                   message.messageId)

proc getTitle(message: Message): string =
  block:
    return message.chat.title.getOrBreak
  block:
    return message.from.getOrBreak.fullName
  return "Unknown"

proc rememberChat(bot: Bot, update: Update) =
  update.message ?-> message:
    bot.db.rememberChat(message.chat.id, message.getTitle)

proc process*(bot: Bot, update: Update) {.async.} =
  rememberUsers(bot, update)
  rememberLast(bot, update)
  rememberChat(bot, update)
