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

proc main(token, dbPath, logPath: string) {.async.} =
  let logFile = open(logPath, mode = fmAppend)
  let bot = await newBot(token, dbPath)
  while true:
    let updates = await bot.tg.getUpdates(logFile = logFile)
    for update in updates:
      await runModules(bot, update)

let dbPath = paramStr(1)
let logPath = paramStr(2)
let token = stdin.readLine()
randomize()
asyncCheck main(token, dbPath, logPath)
runForever()
