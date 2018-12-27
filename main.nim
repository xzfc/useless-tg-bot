# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ./bot
import ./telega/req
import asyncdispatch
import macros
import os
import random

static:
  discard staticExec"""
    printf 'from %-20s import nil\n' modules/*.nim | sed 's/\.nim / /' > autogen_modules.nim
  """
import autogen_modules
prepareModules()

proc main(token, dbPath, logPath, markovPath: string) {.async.} =
  let logFile = open(logPath, mode = fmAppend)
  let bot = await newBot(token, dbPath, markovPath)
  while true:
    let updates = await bot.tg.getUpdates(logFile = logFile)
    for update in updates:
      await runModules(bot, update)

let dbPath = paramStr(1)
let logPath = paramStr(2)
let markovPath = paramStr(3)
let token = stdin.readLine()
randomize()
asyncCheck main(token, dbPath, logPath, markovPath)
runForever()
