import options
import sets
import typetraits
import tables
import macros
import strutils
import sequtils
import json
import ./types

type TelegaParsingError* = object of ValueError

proc telegaNormalize(s: string): string =
  ## Convert camelCase to snake_case.
  result = ""
  for c in s:
    if c in {'A' .. 'Z'}:
      result.add('_')
      result.add(c.toLowerAscii)
    else:
      result.add(c)

proc assertKind(node: JsonNode, kind: JsonNodeKind) =
  if isNil(node) or node.kind != kind:
    raise newException(TelegaParsingError, "Node is not " & $kind)

proc get(node: JsonNode, name: string): JsonNode =
  if node.fields.hasKey name:
    node.fields[name]
  else:
    nil

macro generateParseNode(T: typedesc): untyped =
  proc mkStringLit(sym: NimNode): NimNode =
    newStrLitNode(telegaNormalize($sym))

  proc mkParseNode(sym: NimNode): NimNode {.compileTime.} =
    let lit = newStrLitNode(telegaNormalize($sym))
    quote do:
      node.get(`lit`).parseNode res.`sym`

  let typeNode = T.getType
  expectKind(typeNode, nnkBracketExpr)
  doAssert(($typeNode[0]).normalize == "typedesc")
  expectKind(typeNode[1], nnkSym)
  let keys = typeNode[1].getType[2].toSeq()

  let keyNames = newNimNode(nnkBracket).add(keys.map(mkStringLit))

  let assertStmt = quote do:
    node.assertKind JObject
    const validKeys = toSet(`keyNames`)
    for p in node.pairs:
      if not validKeys.contains(p.key):
        echo "Warning: unexpected key " & p.key & " at " & `T`.name


  let parseStatements = keys.map(mkParseNode)
  newStmtList(assertStmt).add(parseStatements)

proc parseNode(node: JsonNode, res: var string)

proc parseNode[T](node: JsonNode, res: var Option[T]) =
  if isNil(node):
    res = none(T)
  else:
    var res1: T
    node.parseNode res1
    res = some(res1)

proc parseNode[T](node: JsonNode, res: var ref T) =
  if isNil(node):
    res = nil
  else:
    new(res)
    node.parseNode res[]

proc parseNode[T](node: JsonNode, res: var seq[T]) =
  node.assertKind JArray
  let elems = node.getElems
  res = newSeq[T](elems.len)
  var i = 0
  for elem in elems:
    elem.parseNode res[i]
    inc i

proc parseNode(node: JsonNode, res: var bool) =
  node.assertKind JBool
  res = node.getBVal()
    
proc parseNode(node: JsonNode, res: var string) =
  node.assertKind JString
  res = node.getStr()

proc parseNode(node: JsonNode, res: var int32) =
  node.assertKind JInt
  res = node.getNum().int32

proc parseNode(node: JsonNode, res: var int64) =
  node.assertKind JInt
  res = node.getNum().int64

proc parseNode(node: JsonNode, res: var uint) =
  node.assertKind JInt
  res = node.getNum().uint

proc parseNode(node: JsonNode, res: var ChatType) =
  node.assertKind JString
  case node.getStr()
  of "private":    res = ctPrivate
  of "group":      res = ctGroup
  of "supergroup": res = ctSupergroup
  of "channel":    res = ctChannel
  else:            res = ctUnknown

proc parseNode(node: JsonNode, res: var MessageEntityType) =
  node.assertKind JString
  case node.getStr()
  of "mention":      res = metMention
  of "hashtag":      res = metHashtag
  of "bot_command":  res = metBotCommand
  of "url":          res = metUrl
  of "email":        res = metEmail
  of "bold":         res = metBold
  of "italic":       res = metItalic
  of "code":         res = metCode
  of "pre":          res = metPre
  of "text_link":    res = metTextLink
  of "text_mention": res = metTextMention
  else:              res = metUnknown

proc parseNode(node: JsonNode, res: var Chat) =
  generateParseNode Chat

proc parseNode(node: JsonNode, res: var User) =
  generateParseNode User

proc parseNode(node: JsonNode, res: var PhotoSize) =
  generateParseNode PhotoSize

proc parseNode(node: JsonNode, res: var Sticker) =
  generateParseNode Sticker

proc parseNode(node: JsonNode, res: var Document) =
  generateParseNode Document

proc parseNode(node: JsonNode, res: var MessageEntity) =
  node.assertKind JObject
  reset res
  var `type`: MessageEntityType
  node.get("type").parseNode   `type`
  res.`type` = `type`
  node.get("offset").parseNode res.offset
  node.get("length").parseNode res.length
  case `type`:
    of metTextLink:    node.get("url").parseNode  res.url
    of metTextMention: node.get("user").parseNode res.user
    else: discard

proc parseNode(node: JsonNode, res: var Message) =
  generateParseNode Message

proc parseNode(node: JsonNode, res: var Update) =
  generateParseNode Update

proc parseUpdates*(node: JsonNode): seq[Update] =
  #try:
    node.parseNode result
  #except:
  #  echo getCurrentExceptionMsg()
  #  result = @[]

proc parseUser*(node: JsonNode): User =
  node.parseNode result
