# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/types
import asyncdispatch
import options
import sequtils
import sets

MODULE(priority = 10)

proc date(update: Update): int32 =
  let msg =
    update.message //
    update.editedMessage //
    update.channelPost //
    update.editedChannelPost
  msg ?-> msg:
    return (msg.editDate // msg.forwardDate // msg.date.some).get
  else:
    # Should not be used by rememberUser
    return 0

proc rememberUsers(bot: Bot, update: Update) =
  var handledUsers = initSet[int64]()
  let now = update.date
  proc handleUser(user: User) =
    if not handledUsers.contains user.id:
      handledUsers.incl user.id
      bot.db.rememberUser(user, now)
  proc handleUsers(users: seq[User]) =
    for user in users:
      handleUser user
  proc handleEntity(entity: MessageEntity) =
    if entity.kind == meTextMention:
      bot.db.rememberUser(entity.user, now)
  proc handleMessage(msg: Message) =
    msg.fromUser.map       handleUser
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
  proc getDocument(m: Message): Option[string] =
    m.sticker  ?-> x:
      return x.fileId.some
    m.document ?-> x:
      if x.mimeType == "video/mp4".some:
        return x.fileId.some
    return string.none
  block:
    let message = update.message.getOrBreak
    let userId = message.fromUser.getOrBreak.id
    bot.db.rememberLastUserMessage(message.chat.id, userId, message.messageId)
    bot.db.rememberLastUserDocument(message.chat.id,
                                    userId,
                                    message.getDocument.getOrBreak)

proc rememberChat(bot: Bot, update: Update) =
  update.message ?-> message:
    if message.chat.id >= 0:
      return
    let chatTitle = message.chat.title.get("Unknown")
    # Remember group
    bot.db.rememberChat(message.chat.id, chatTitle)
    message.fromUser ?-> user:
      # Assign user to current cluster
      bot.db.rememberChatUser(user.id,
                              user.fullName &  " @ " & chatTitle,
                              message.chat.id)
    message.leftChatMember ?-> user:
      # Remove user from cluster
      bot.db.forgetChatUser(user.id)

proc process(bot: Bot, update: Update) {.async.} =
  rememberUsers(bot, update)
  rememberLast(bot, update)
  rememberChat(bot, update)
