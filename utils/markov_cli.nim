# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import ./markov_lib
import db_sqlite
import os
import strutils
import system

proc learnFromStdin(m: Markov) =
  var line: string
  m.db.exec sql"BEGIN TRANSACTION"
  while stdin.readLine(line):
    let s = line.split(maxsplit = 2)
    m.learn(s[0].parseInt, s[1].parseInt, s[2], false)
  m.db.exec sql"COMMIT TRANSACTION"

if paramCount() == 2 and paramStr(1) == "learn":
  let m = newMarkov(paramStr(2))
  m.learnFromStdin
elif paramCount() == 4 and paramStr(1) == "generate":
  let m = newMarkov(paramStr(2))
  for i in 0..1000:
    echo m.generate(paramStr(3).parseInt, paramStr(4), 50)
else:
  echo "Usage:"
  echo "  ./learn.sh < data/log.txt | markov_cli learn data/markov.db"
  echo "  markov_cli generate data/markov.db 1234 \"initial text\""
  quit 1
