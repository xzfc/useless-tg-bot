# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

var c_LC_ALL {.header: "<locale.h>", importc: "LC_ALL".}: int
proc c_setlocale(category: int, other: cstring): cstring {.header: "<locale.h>", importc: "setlocale".}
proc c_bindtextdomain(domainname: cstring; dirname: cstring): cstring {.header: "<libintl.h>",importc: "bindtextdomain".}
proc c_textdomain(domainname: cstring): cstring {.header: "<libintl.h>", importc: "textdomain".}
proc c_gettext(msgid: cstring): cstring {.header: "<libintl.h>", importc: "gettext".}
proc c_ngettext(msgid1: cstring; msgid2: cstring; n: culong): cstring {.header: "<libintl.h>", importc: "ngettext".}

import strutils
import ospaths

proc gettextInit*() =
  discard c_setlocale(c_LC_ALL, "")
  putEnv("LANGUAGE", "ru")
  discard c_bindtextdomain("holy", "po")
  discard c_textdomain("holy")

proc gettext*(msgid: cstring): string =
  $c_gettext(msgid)

proc ngettext*(msgid1: cstring, msgid2: cstring, n: int64): string =
  $c_ngettext(msgid1, msgid2, n.culong)

template pgettext*(msgctxt: cstring, msgid: string): string =
  # The following code was simple in C, but Nim requires it to be a little bit
  # complicated.

  # Make sure string concatenation won't be at runtime.
  const concat = (msgctxt & "\x04" & msgid).cstring

  # Make sure Nim compiler won't inline same string literal twice.
  let concat1 = concat

  let translation = c_gettext(concat1)

  # Make sure Nim compiler generate pointer comparsion, not strcmp.
  if cast[pointer](translation) == cast[pointer](concat1):
    msgid
  else:
    $translation
