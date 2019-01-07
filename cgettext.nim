# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

var c_LC_ALL {.header: "<locale.h>", importc: "LC_ALL".}: int
proc c_setlocale(category: int, other: cstring): cstring {.header: "<locale.h>", importc: "setlocale".}
proc c_bindtextdomain(domainname: cstring; dirname: cstring): cstring {.header: "<libintl.h>",importc: "bindtextdomain".}
proc c_textdomain(domainname: cstring): cstring {.header: "<libintl.h>", importc: "textdomain".}
proc c_gettext(msgid: cstring): cstring {.header: "<libintl.h>", importc: "gettext".}
proc c_ngettext(msgid1: cstring; msgid2: cstring; n: culong): cstring {.header: "<libintl.h>", importc: "ngettext".}

import strutils

proc gettextInit*() =
  discard c_setlocale(c_LC_ALL, "ru_RU.UTF-8")
  discard c_bindtextdomain("holy", "po")
  discard c_textdomain("holy")

proc gettext*(msgid: cstring): string =
  $c_gettext(msgid)

proc ngettext*(msgid1: cstring, msgid2: cstring, n: int64): string =
  $c_ngettext(msgid1, msgid2, n.culong)
