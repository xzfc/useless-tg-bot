import ../bot
import ../db
import ../sweet_options
import ../telega/html
import ../telega/req
import ../telega/types
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
  (?<user> @[a-zA-Z0-9_]+ | <user\ ent=1>[^<]*<\/user> )
  \ *
  $
"""

let is_about_cmd_user = re r"""(*UTF8)(?x)
  /[@a-zA-Z_]+
  \ +
  (?<cmd>by|del)
  \ +
  (?<user> @[a-zA-Z0-9_]+ | <user\ ent=1>[^<]*<\/user> )
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

let help = """
Команды:
@$1 -- сплетница
/about @$1
/about by @$1
/about del @$1
/about rating
"""

proc htmlEscape(s: string): string =
  result = ""
  for c in items(s):
    case c
    of '<': add(result, "&lt;")
    of '>': add(result, "&gt;")
    of '&': add(result, "&amp;")
    else:   add(result, c)
  return result

proc at[T](s: seq[T], idx: int): Option[T] =
  if idx < 0 or idx >= s.len:
    none(T)
  else:
    some(s[idx])

proc renderTime(t: Time): string =
  if t < 1514764800.Time:
    ", 2017"
  else:
    ""

proc fullName(user: DbUser): string =
  (if user.deleted: "†" else: "") & user.toUser.fullName.htmlEscape 

proc fullNameRating(user: DbUser): string =
  if not user.deleted:
    user.toUser.fullName.htmlEscape
  else:
    "†" & user.toUser.fullName.htmlEscape & " @" & $user.id

proc renderRow(row: OpinionRow): string =
  "$1 — $2 <i>($3$4)</i>" % [
    row.subj.fullName.htmlEscape,
    row.text,
    row.author.fullName.htmlEscape,
    row.datetime.renderTime]

proc renderRatingRow(row: OpinionRatingRow): string =
  "<code>$1 $2</code> $3" % [
    ($row.asSubj).align 2,
    ($row.asAuthor).align 2,
    row.user.fullNameRating]

proc renderRowsAbout(subj: User, rows: seq[OpinionRow]): string =
  if rows.len == 0:
    "Ещё никто не говорил о $1." % [subj.fullName.htmlEscape]
  else:
    rows.map(renderRow).join("\n")

proc renderRowsBy(subj: User, rows: seq[OpinionRow]): string =
  if rows.len == 0:
    "$1 ещё ни о ком не говорил." % [subj.fullName.htmlEscape]
  else:
    rows.map(renderRow).join("\n")

proc renderRatingRows(rows: seq[OpinionRatingRow]): string =
  if rows.len == 0:
    "But nobody came."
  else:
    rows.map(renderRatingRow).join("\n")

proc getUser(bot: Bot, mention: string, user: Option[MessageEntity]
            ): Option[User] =
  if mention.startsWith '@':
    try:
      bot.db.searchUserByUid(mention[1..^1].parseInt.int32).map(toUser)
    except ValueError:
      bot.db.searchUserByUname(mention[1..^1]).map(toUser)
  else:
    some user.get.user

template reply(text: string) =
  asyncCheck bot.tg.reply(update.message.get,
                          text,
                          parseMode="HTML",
                          disableWebPagePreview=true)

proc process*(bot: Bot, update: Update) {.async.} =
  if (update.message?.text).isNone or (update.message?.`from`).isNone:
    return
  let message = update.message.get
  let chatId = message.chat.id
  let `from` = message.`from`.get
  let text = message.text.get
  let entities = message.entities ?: @[]
  let html = render_entities(text, entities)

  if update.isCommand(bot, "about"):
    html.match(is_about_user) ?-> match:
      getUser(bot, match.captures["user"], entities.at 1) ?-> user:
        let rows = bot.db.searchOpinionsBySubjUid(chatId, user.id)
        reply renderRowsAbout(user, rows)
      else:
        reply "Не видела тут $1." % [match.captures["user"]]
      return
    html.match(is_about_cmd_user) ?-> match:
      getUser(bot, match.captures["user"], entities.at 1) ?-> user:
        if match.captures["cmd"] == "by":
          let rows = bot.db.searchOpinionsByAuthorUid(chatId, user.id)
          reply renderRowsBy(user, rows)
        else:
          let old = bot.db.searchOpinion(chatId, `from`.id, user.id)
          if old.isSome:
            bot.db.forgetOpinion(chatId, `from`.id, user.id)
            reply "Удалила!"
          else:
            reply "..."
        return
      else:
        reply "Не видела тут $1." % [match.captures["user"]]
      return
    html.match(is_about_all) ?-> match:
      let rows = bot.db.searchOpinionsRating(chatId)
      reply renderRatingRows(rows)
      return
    if text == "/about":
      reply help % [bot.me.username.unsafeGet]
      return
    reply "..."
  else:
    render_entities(text, entities).match(is_re) ?-> match:
      getUser(bot, match.captures["user"], entities.at 0) ?-> user:
        let old = bot.db.searchOpinion(chatId, `from`.id, user.id)
        bot.db.rememberOpinion(chatId, `from`.id, user.id,
                               match.captures["text"].cleanEntities)
        if old.isSome:
          reply "Переписала!"
        else:
          reply "Записала!"
      else:
        reply "Не видела тут $1." % [match.captures["user"]]
