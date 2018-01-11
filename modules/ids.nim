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
  proc handleUsers(users: seq[User]) =
    for user in users:
      handleUser user
  proc handleEntity(entity: MessageEntity) =
    if entity.`type` == metTextMention:
      bot.db.rememberUser entity.user
  proc handleMessage(msg: Message) =
    msg.`from`.map         handleUser
    msg.forwardFrom.map    handleUser
    msg.newChatMembers.map handleUsers
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

proc rememberChat(bot: Bot, update: Update) =
  update.message ?-> message:
    if message.chat.id >= 0:
      return
    let chatTitle = message.chat.title.get("Unknown")
    # Remember group
    bot.db.rememberChat(message.chat.id, chatTitle)
    message.`from` ?-> user:
      # Assign user to current cluster
      bot.db.rememberChatUser(user.id,
                              user.fullName &  " @ " & chatTitle,
                              message.chat.id)
    message.leftChatMember ?-> user:
      # Remove user from cluster
      bot.db.forgetChatUser(user.id)

proc process*(bot: Bot, update: Update) {.async.} =
  rememberUsers(bot, update)
  rememberLast(bot, update)
  rememberChat(bot, update)
