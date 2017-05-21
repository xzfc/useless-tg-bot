import options
import nre
import strutils
import unicode
import unittest
import ./types
import ../sweet_options

proc render_entities*(text: string, entities: seq[MessageEntity]): string =
  result = ""
  var pos = 0.int32
  var ent = 0
  var inside = false

  proc apply_ent(result : var string) =
    if ent < entities.len and inside and pos == entities[ent].offset + entities[ent].length:
      case entities[ent].type0:
      of metItalic:      result.add "</i>"
      of metBold:        result.add "</b>"
      of metCode:        result.add "</code>"
      of metPre:         result.add "</pre>"
      of metTextLink:    discard # TODO # result.add "<a href=\""  "\">"
      of metTextMention: result.add "</user>"
      else: discard
      inside = false
      inc ent
    if ent < entities.len and not inside and pos == entities[ent].offset:
      case entities[ent].type0:
      of metItalic:      result.add "<i>"
      of metBold:        result.add "<b>"
      of metCode:        result.add "<code>"
      of metPre:         result.add "<pre>"
      of metTextLink:    discard # TODO # result.add "<a href=\""  "\">"
      of metTextMention: result.add "<user ent=" & $ent & ">"
      else: discard
      inside = true

  apply_ent result
  for c in runes(text):
    case c.int32
    of ord '<': result.add "&lt;"; inc pos
    of ord '>': result.add "&gt;"; inc pos
    of ord '&': result.add "&amp;"; inc pos
    of 0 .. ord('&')-1,
       ord('&') + 1 .. ord('<') - 1,
       ord('>') + 1 .. 0xFFFF: result.add c.toUTF8; inc pos
    of 0x10000 .. int32.high: result.add c.toUTF8; inc pos; inc pos
    apply_ent result

proc utf16Prefix*(text: string, length: int): string =
  result = ""
  if length != 0:
    var pos = 0
    for c in text.runes:
      result.add c.toUTF8
      inc pos
      if c.int32 >= 0x10000:
        inc pos
      if pos >= length:
        break

let cleanRe = re"<user ent=[0-9]+>|</user>"
proc cleanEntities*(text: string): string =
  return text.replace(cleanRe, "")

proc fullName*(user: User): string =
  user.last_name ?-> lastName:
    user.first_name & " " & last_name
  else:
    user.first_name

 # #        ##### #####  #### #####  #### 
#####         #   #     #       #   #     
 # #          #   ####   ###    #    ###  
#####         #   #         #   #       # 
 # #          #   ##### ####    #   ####  


proc bold(offset, length: int32) : MessageEntity =
  result.type0 = metBold
  result.offset = offset
  result.length = length

proc user(offset, length: int32) : MessageEntity =
  result.type0 = metTextMention
  result.offset = offset
  result.length = length
  result.user.id = 123
  result.user.first_name = "first"

suite "render_entities":
  test "all":
    check render_entities("foo bar baz", @[ bold(4,3) ]) ==
          "foo <b>bar</b> baz"
    check render_entities("bar baz", @[ bold(0,3) ]) ==
          "<b>bar</b> baz"
    check render_entities("foo bar", @[ bold(4,3) ]) ==
          "foo <b>bar</b>"
    check render_entities("foo bar baz", @[ bold(4,3), bold(7,4) ]) ==
          "foo <b>bar</b><b> baz</b>"
    check render_entities("foo bar baz", @[ bold(4,3), bold(8,3) ]) ==
          "foo <b>bar</b> <b>baz</b>"
    check render_entities("foo 𐅁𐅀 bar 𐅁𐅀 baz", @[ bold(4,4), bold(13, 4) ]) ==
          "foo <b>𐅁𐅀</b> bar <b>𐅁𐅀</b> baz"
    check render_entities("foo bar baz", @[ bold(4,3), user(8,3) ]) ==
          "foo <b>bar</b> <user ent=1>baz</user>"

suite "clean_entities":
  test "none":
    check "foo <b>bar</b> baz".clean_entities == "foo <b>bar</b> baz"
  test "one":
    check "foo <user ent=32>bar</user> baz".clean_entities == "foo bar baz"
  test "multiline":
    check "foo <user ent=32>ba\nr</user> baz".clean_entities == "foo ba\nr baz"

suite "utf16Prefix":
  test "len is 0, empty":
    check "".utf16Prefix(0) == ""
  test "len is 0, not empty":
    check "foo".utf16Prefix(0) == ""
  test "full":
    check "foo".utf16Prefix(3) == "foo"
  test "ascii":
    check "foo bar".utf16Prefix(3) == "foo"
  test "wide":
    check "𐅁𐅀 bar".utf16Prefix(4) == "𐅁𐅀"
