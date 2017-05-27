import ./bot
import ./modules/about as module_about
import ./modules/ids as module_ids
import ./modules/markov as module_markov
import ./modules/reply as module_reply
import ./telega/req
import asyncdispatch
import os
import random

proc main(token, dbPath, logPath: string) {.async.} =
  let logFile = open(logPath, mode = fmAppend)
  let bot = await newBot(token, dbPath)
  while true:
    let updates = await bot.tg.getUpdates(logFile = logFile)
    for update in updates:
      await module_ids.process(bot, update)
      await module_about.process(bot, update)
      await module_markov.process(bot, update)
      await module_reply.process(bot, update)

let dbPath = paramStr(1)
let logPath = paramStr(2)
let token = stdin.readLine()
randomize()
asyncCheck main(token, dbPath, logPath)
runForever()
