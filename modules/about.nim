# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ../bot
import ../cgettext
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import ../telega/yoba
import asyncdispatch
import db_sqlite
import json
import nre
import options
import sequtils
import strutils
import times

MODULE()

let is_re = re(r"""(*UTF8)(?x)
  (?<user> @[a-zA-Z0-9_]+ | <user\ ent=0>[^<]*<\/user> )
  \ *(?:—|--|–)\ *
  (?<text>[^\ ].*)
  $
""")

let is_about_user = re r"""(*UTF8)(?x)
  \/[@a-zA-Z_]+
  \ +
  (?<user> @[a-zA-Z0-9_]+ | <user\ ent=1>[^<]*<\/user> | me )
  \ *
  $
"""

let is_about_cmd_user = re r"""(*UTF8)(?x)
  /[@a-zA-Z_]+
  \ +
  (?<cmd>by|del)
  \ +
  (?<user> @[a-zA-Z0-9_]+ | <user\ ent=1>[^<]*<\/user> | me )
  \ *
  $
"""

let is_about_cmd = re r"""(*UTF8)(?x)
  /[@a-zA-Z_]+
  \ +
  (?<cmd>rating|latest)
  \ *
  $
"""

proc htmlEscape(s: string): string =
  result = newStringOfCap s.len
  for c in s.items:
    case c
    of '<': result.add "&lt;"
    of '>': result.add "&gt;"
    of '&': result.add "&amp;"
    else:   result.add c

proc at[T](s: seq[T], idx: int): Option[T] =
  if idx < 0 or idx >= s.len:
    none(T)
  else:
    some(s[idx])

proc fullName(user: DbUser): string =
  let name = user.toUser.fullName.htmlEscape
  if user.deleted:
    "†" & name
  else:
    "<a href=\"tg://user?id=" & $user.id & "\">" & name & "</a>"

proc fullNameRating(user: DbUser): string =
  let name = user.toUser.fullName.htmlEscape
  if user.deleted:
    "†" & name & " @" & $user.id
  else:
    "<a href=\"tg://user?id=" & $user.id & "\">" & name & "</a>"

proc renderRowsAbout(subj: User, rows: seq[OpinionRow]): string =
  proc renderTime(t: int64): string =
    if t < 1514764800:
      ", 2017"
    else:
      ""
  proc renderRow(row: OpinionRow): string =
    "— $1 ($2$3)" % [
      row.text,
      row.author.fullName,
      row.datetime.renderTime]
  if rows.len == 0:
    pgettext("about", "!no-about! $1") % [subj.fullName.htmlEscape]
  else:
    rows.map(renderRow).join("\n")

proc renderRowsBy(subj: User, rows: seq[OpinionRow]): string =
  proc renderTime(t: int64): string =
    if t < 1514764800:
      " <i>(2017)</i>"
    else:
      ""
  proc renderRow(row: OpinionRow): string =
    "$1 — $2$3" % [
      row.subj.fullName,
      row.text,
      row.datetime.renderTime]
  if rows.len == 0:
    pgettext("about", "!no-about-by! $1") % [subj.fullName.htmlEscape]
  else:
    rows.map(renderRow).join("\n")

proc renderLatestRows(rows: seq[OpinionRow]): string =
  proc renderTime(t: int64): string =
    if t < 1514764800:
      ", 2017"
    else:
      ""
  proc renderRow(row: OpinionRow): string =
    "$1 — $2 ($3)" % [
      row.subj.fullName,
      row.text,
      row.author.fullName]
  if rows.len == 0:
    pgettext("about", "!empty-rating!")
  else:
    rows.map(renderRow).join("\n")

proc renderRatingRows(rows: seq[OpinionRatingRow]): string =
  proc renderRow(row: OpinionRatingRow): string =
    "<code>$1 $2</code> $3" % [
      ($row.asSubj).align 2,
      ($row.asAuthor).align 2,
      row.user.fullNameRating]
  if rows.len == 0:
    pgettext("about", "!empty-rating!")
  else:
    rows.map(renderRow).join("\n")

proc getUser(bot: Bot,
             mention: string,
             fromUser: User,
             user: Option[MessageEntity]
            ): Option[User] =
  if mention == "me":
    some fromUser
  elif mention.startsWith '@':
    try:
      bot.db.searchUserByUid(mention[1..^1].parseInt.int32).map(toUser)
    except ValueError:
      bot.db.searchUserByUname(mention[1..^1]).map(toUser)
  else:
    some user.get.user

template reply(text: string) =
  let m = yoba.replyWithTextMentions(bot, message, text, chatId < 0)
  if readonly:
    asyncCheck m.markDeleteable(bot)
  else:
    asyncCheck m

proc process(bot: Bot, update: Update) {.async.} =
  if (update.message?.text).isNone or (update.message?.fromUser).isNone:
    return
  let message = update.message.get
  let chatId = message.chat.id
  let fromUser = message.fromUser.get
  let text = message.text.get
  let entities = message.entities ?: @[]
  let html = render_entities(text, entities)
  var readonly = true

  if update.isCommand(bot, "about"):

    # /about @user
    html.match(is_about_user) ?-> match:
      getUser(bot, match.captures["user"], fromUser, entities.at 1) ?-> user:
        let rows = bot.db.searchOpinionsBySubjUid(chatId, user.id)
        reply renderRowsAbout(user, rows)
      else:
        reply pgettext("about", "!unknown-user! $1") % [match.captures["user"]]
      return

    # /about [by/del] @user
    html.match(is_about_cmd_user) ?-> match:
      getUser(bot, match.captures["user"], fromUser, entities.at 1) ?-> user:
        if match.captures["cmd"] == "by":
          let rows = bot.db.searchOpinionsByAuthorUid(chatId, user.id)
          reply renderRowsBy(user, rows)
        elif chatId < 0:
          readonly = false
          let old = bot.db.searchOpinion(chatId, fromUser.id, user.id)
          if old.isSome:
            bot.db.forgetOpinion(chatId, fromUser.id, user.id)
            reply pgettext("about", "Deleted!")
          else:
            reply "..."
        else:
          reply pgettext("about", "!cant-delete!")
        return
      else:
        reply pgettext("about", "!unknown-user! $1") % [match.captures["user"]]
      return

    # /about [rating/latest]
    html.match(is_about_cmd) ?-> match:
      if match.captures["cmd"] == "rating":
        let rows = bot.db.searchOpinionsRating(chatId)
        reply renderRatingRows(rows)
      else:
        let rows = bot.db.searchOpinionsLatest(chatId, 10)
        reply renderLatestRows(rows)
      return

    # /about
    if not text.contains(' '):
      reply pgettext("about", "!help!") % [bot.me.username.unsafeGet]
      return

    reply "..."

  else:
    # @user -- blabla
    render_entities(text, entities).match(is_re) ?-> match:
      if chatId >= 0:
        reply pgettext("about", "!cant-add!")
        return
      getUser(bot, match.captures["user"], fromUser, entities.at 0) ?-> user:
        readonly = false
        let old = bot.db.searchOpinion(chatId, fromUser.id, user.id)
        bot.db.rememberOpinion(chatId, fromUser.id, user.id,
                               match.captures["text"].cleanEntities)
        if old.isSome:
          reply pgettext("about", "Updated!")
        else:
          reply pgettext("about", "Added!")
      else:
        reply pgettext("about", "!unknown-user! $1") % [match.captures["user"]]
