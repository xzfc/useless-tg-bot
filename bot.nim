# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ./db
import ./telega/req
import ./telega/types
import ./utils/markov_lib
import algorithm
import asyncdispatch
import ndb/sqlite
import options
import strutils

type
  Bot* = ref object
    tg *: Telega
    db *: DbConn
    me *: User
    markov *: Markov

proc newBot*(token, dbPath, markovPath: string): Future[Bot] {.async.} =
  new(result)
  result.tg = newTelega(token)
  result.db = open(dbPath, "", "", "")
  result.db.init
  result.me = await result.tg.getMe()
  result.markov = newMarkov(markovPath)

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


type
  ProcessUpdateCb = proc (bot: Bot, update: Update): Future[void]
  BotModule = object
    priority      : int
    processUpdate : ProcessUpdateCb

var modules = newSeq[BotModule]()

proc registerModule*(cb: ProcessUpdateCb, priority: int) =
  modules.add BotModule(processUpdate: cb, priority: priority)

proc runModules*(bot: Bot, update: Update) {.async.} =
  for m in modules:
    await m.processUpdate(bot, update)

proc prepareModules*() =
  modules.sort do (x, y: BotModule) -> int:
    cmp(y.priority, x.priority)

template MODULE*(priority: int = 0) {.dirty.} =
  # Assume each module have `process` proc
  proc process(bot: Bot, update: Update): Future[void]
  registerModule(process, priority)
