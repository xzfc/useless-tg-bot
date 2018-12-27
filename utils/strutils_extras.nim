# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import strutils
import unittest

proc unindentEx(s: string): string =
  var count = 1000
  for line in s.splitLines():
    for j in 0..<line.len:
      if line[j] != ' ':
        if count > j:
          count = j
        break
  s.unindent(count).strip(chars=NewLines)

suite "unindentEx":
  test "all":
    check unindentEx("""
      foo
        bar
        baz
      qoox
    """) == "foo\n  bar\n  baz\nqoox"
