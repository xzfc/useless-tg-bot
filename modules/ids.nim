import ../bot
import ../db
import ../telega/types
import asyncdispatch
import options
import sequtils

proc process*(bot: Bot, update: Update) {.async.} =
  proc handleUser(user: User) =
    bot.db.rememberUser user
  proc handleEntity(entity: MessageEntity) =
    if entity.type0 == metTextMention:
      bot.db.rememberUser entity.user
  proc handleMessage(msg: Message) =
    msg.from0.map            handleUser
    msg.forward_from.map     handleUser
    msg.new_chat_member.map  handleUser
    msg.left_chat_member.map handleUser
    if msg.entities.isSome:
      for entity in msg.entities.get:
        handleEntity entity
    if not msg.reply_to_message.isNil:
      msg.reply_to_message[].handleMessage
    if not msg.pinnedMessage.isNil:
      msg.pinnedMessage[].handleMessage
  update.message.map             handleMessage
  update.edited_message.map      handleMessage
  update.channel_post.map        handleMessage
  update.edited_channel_post.map handleMessage

