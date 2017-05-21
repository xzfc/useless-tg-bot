import ./db
import ./telega/req
import ./telega/types
import asyncdispatch
import db_sqlite
import options
import strutils

type
  Bot* = ref object
    tg *: Telega
    db *: DbConn
    me *: User

proc newBot*(token, dbPath: string): Future[Bot] {.async.} =
  new(result)
  result.tg = newTelega(token)
  result.db = open(dbPath, nil, nil, nil)
  result.db.init
  result.me = await result.tg.getMe()

proc isCommand*(update: Update, bot: Bot, cmd: string): bool =
  if update.message.isNone:
    return false
  let message = update.message.get
  if message.text.isNone:
    return false
  let text = message.text.get
  let v1 = "/" & cmd
  let v2 = "/" & cmd & "@" & bot.me.username.get
  return text == v1 or text == v2 or
         text.startsWith(v1 & " ") or text.startsWith(v2 & " ")
