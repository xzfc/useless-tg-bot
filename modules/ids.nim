import ../bot
import ../db
import ../sweet_options
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
  update.message ?-> message:
    message.`from` ?-> from0:
      bot.db.rememberLastUserMessage(message.chat.id,
                                     from0.id,
                                     message.messageId)

proc process*(bot: Bot, update: Update) {.async.} =
  rememberUsers(bot, update)
  rememberLast(bot, update)
