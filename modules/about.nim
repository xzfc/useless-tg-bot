import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
import ../texts
import asyncdispatch
import db_sqlite
import json
import nre
import options
import sequtils
import strutils
import times

let is_re = re(r"""(*UTF8)(?x)
  (?<user> @[a-zA-Z0-9_]+ | <user\ ent=0>[^<]*<\/user> )
  \ *(?:—|--)\ *
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

let is_about_all = re r"""(*UTF8)(?x)
  /[@a-zA-Z_]+
  \ +
  rating
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
  (if user.deleted: "†" else: "") & user.toUser.fullName.htmlEscape

proc fullNameRating(user: DbUser): string =
  if not user.deleted:
    user.toUser.fullName.htmlEscape
  else:
    "†" & user.toUser.fullName.htmlEscape & " @" & $user.id

proc renderRowsAbout(subj: User, rows: seq[OpinionRow]): string =
  proc renderTime(t: Time): string =
    if t < 1514764800.Time:
      ", 2017"
    else:
      ""
  proc renderRow(row: OpinionRow): string =
    "— $1 <i>($2$3)</i>" % [
      row.text,
      row.author.fullName.htmlEscape,
      row.datetime.renderTime]
  if rows.len == 0:
    texts.aboutNoAbout % [subj.fullName.htmlEscape]
  else:
    rows.map(renderRow).join("\n")

proc renderRowsBy(subj: User, rows: seq[OpinionRow]): string =
  proc renderTime(t: Time): string =
    if t < 1514764800.Time:
      " <i>(2017)</i>"
    else:
      ""
  proc renderRow(row: OpinionRow): string =
    "$1 — $2$3" % [
      row.subj.fullName.htmlEscape,
      row.text,
      row.datetime.renderTime]
  if rows.len == 0:
    texts.aboutNoAboutBy % [subj.fullName.htmlEscape]
  else:
    rows.map(renderRow).join("\n")

proc renderRatingRows(rows: seq[OpinionRatingRow]): string =
  proc renderRow(row: OpinionRatingRow): string =
    "<code>$1 $2</code> $3" % [
      ($row.asSubj).align 2,
      ($row.asAuthor).align 2,
      row.user.fullNameRating]
  if rows.len == 0:
    texts.aboutEmptyRating
  else:
    rows.map(renderRow).join("\n")

proc getUser(bot: Bot,
             mention: string,
             `from`: User,
             user: Option[MessageEntity]
            ): Option[User] =
  if mention == "me":
    some `from`
  elif mention.startsWith '@':
    try:
      bot.db.searchUserByUid(mention[1..^1].parseInt.int32).map(toUser)
    except ValueError:
      bot.db.searchUserByUname(mention[1..^1]).map(toUser)
  else:
    some user.get.user

proc reply2(bot: Bot, message: Message, text: string,
            deletable: bool) {.async.} =
  let reply = await bot.tg.reply(message,
                                 text,
                                 parseMode="HTML",
                                 disableWebPagePreview=true)
  if deletable:
    reply ?-> reply:
      bot.db.rememberDeletable(reply.chat.id, reply.messageId)

template reply(text: string) =
  asyncCheck reply2(bot, message, text, readonly)

proc process*(bot: Bot, update: Update) {.async.} =
  if (update.message?.text).isNone or (update.message?.`from`).isNone:
    return
  let message = update.message.get
  let chatId = message.chat.id
  let `from` = message.`from`.get
  let text = message.text.get
  let entities = message.entities ?: @[]
  let html = render_entities(text, entities)
  var readonly = true

  if update.isCommand(bot, "about"):

    # /about @user
    html.match(is_about_user) ?-> match:
      getUser(bot, match.captures["user"], `from`, entities.at 1) ?-> user:
        let rows = bot.db.searchOpinionsBySubjUid(chatId, user.id)
        reply renderRowsAbout(user, rows)
      else:
        reply texts.aboutUnknownUser % [match.captures["user"]]
      return

    # /about [by/del] @user
    html.match(is_about_cmd_user) ?-> match:
      getUser(bot, match.captures["user"], `from`, entities.at 1) ?-> user:
        if match.captures["cmd"] == "by":
          let rows = bot.db.searchOpinionsByAuthorUid(chatId, user.id)
          reply renderRowsBy(user, rows)
        elif chatId < 0:
          readonly = false
          let old = bot.db.searchOpinion(chatId, `from`.id, user.id)
          if old.isSome:
            bot.db.forgetOpinion(chatId, `from`.id, user.id)
            reply texts.aboutDeleted
          else:
            reply "..."
        else:
          reply texts.aboutCantDelete
        return
      else:
        reply texts.aboutUnknownUser % [match.captures["user"]]
      return

    # /about rating
    html.match(is_about_all) ?-> match:
      discard match
      let rows = bot.db.searchOpinionsRating(chatId)
      reply renderRatingRows(rows)
      return

    # /about
    if not text.contains(' '):
      reply texts.aboutHelp % [bot.me.username.unsafeGet]
      return

    reply "..."

  else:
    # @user -- blabla
    render_entities(text, entities).match(is_re) ?-> match:
      if chatId >= 0:
        reply texts.aboutCantAdd
        return
      getUser(bot, match.captures["user"], `from`, entities.at 0) ?-> user:
        readonly = false
        let old = bot.db.searchOpinion(chatId, `from`.id, user.id)
        bot.db.rememberOpinion(chatId, `from`.id, user.id,
                               match.captures["text"].cleanEntities)
        if old.isSome:
          reply texts.aboutUpdated
        else:
          reply texts.aboutAdded
      else:
        reply texts.aboutUnknownUser % [match.captures["user"]]
