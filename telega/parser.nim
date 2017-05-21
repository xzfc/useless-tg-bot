import options
import sequtils
import json
import ./types

type TelegaParsingError* = object of ValueError

proc assertKind(node : JsonNode, kind : JsonNodeKind) =
  if isNil(node) or node.kind != kind:
    raise newException(TelegaParsingError, "Node is not " & $kind)

proc parseNode(node : JsonNode, res : var string)

proc parseNode[T](node : JsonNode, res : var Option[T]) =
  if isNil(node):
    res = none(T)
  else:
    var res1 : T
    node.parseNode res1
    res = some(res1)

proc parseNode[T](node : JsonNode, res : var ref T) =
  if isNil(node):
    res = nil
  else:
    new(res)
    node.parseNode res[]

proc parseNode[T](node : JsonNode, res : var seq[T]) =
  node.assertKind JArray
  let elems = node.getElems
  res = newSeq[T](elems.len)
  var i = 0
  for elem in elems:
    elem.parseNode res[i]
    inc i

proc parseNode(node : JsonNode, res : var bool) =
  node.assertKind JBool
  res = node.getBVal()
    
proc parseNode(node : JsonNode, res : var string) =
  node.assertKind JString
  res = node.getStr()

proc parseNode(node : JsonNode, res : var int32) =
  node.assertKind JInt
  res = node.getNum().int32

proc parseNode(node : JsonNode, res : var int64) =
  node.assertKind JInt
  res = node.getNum().int64

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

proc parseNode(node : JsonNode, res : var Chat) =
  node.assertKind JObject
  node["id"].parseNode res.id
  node["title"].parseNode res.title
  node["username"].parseNode res.username
  node["last_name"].parseNode res.last_name
  node["allMembersAreAdministrators"].parseNode res.allMembersAreAdministrators

proc parseNode(node : JsonNode, res : var User) =
  node.assertKind JObject
  node["id"].parseNode          res.id
  node["first_name"].parseNode  res.firstName
  node["last_name"].parseNode   res.lastname
  node["username"].parseNode    res.username

proc parseNode(node : JsonNode, res : var MessageEntity) =
  node.assertKind JObject
  reset res
  var type0 : MessageEntityType
  node["type"].parseNode   type0
  res.type0 = type0
  node["offset"].parseNode res.offset
  node["length"].parseNode res.length
  case type0:
    of metTextLink:    node["url"].parseNode  res.url
    of metTextMention: node["user"].parseNode res.user
    else: discard

proc parseNode(node : JsonNode, res : var Message) =
  node.assertKind JObject
  node["message_id"].parseNode              res.message_id
  node["from"].parseNode                    res.from0
  node["date"].parseNode                    res.date
  node["chat"].parseNode                    res.chat
  node["forward_from"].parseNode            res.forward_from
  node["forward_from_chat"].parseNode       res.forward_from_chat
  node["forward_from_message_id"].parseNode res.forward_from_message_id
  node["forward_date"].parseNode            res.forward_date
  node["reply_to_message"].parseNode        res.reply_to_message
  node["edit_date"].parseNode               res.edit_date
  node["text"].parseNode                    res.text
  node["entities"].parseNode                res.entities
  #audio                 : Option[Audio]
  #document              : Option[Document]
  #game                  : Option[Game]
  #photo                 : Option[seq[PhotoSize]]
  #sticker               : Option[Sticker]
  #video                 : Option[Video]
  #voice                 : Option[Voice]
  node["caption"].parseNode                res.caption
  #contact               : Option[Contact]
  #location              : Option[Location]
  #venue                 : Option[Venue]
  node["new_chat_member"].parseNode          res.new_chat_member
  node["left_chat_member"].parseNode         res.left_chat_member
  node["new_chat_title"].parseNode           res.new_chat_title
  #newChatPhoto          : Option[seq[PhotoSize]]
  node["delete_chat_photo"].parseNode        res.delete_chat_photo
  node["groupChatCreated"].parseNode       res.groupChatCreated
  node["supergroupChatCreated"].parseNode  res.supergroupChatCreated
  node["channelChatCreated"].parseNode     res.channelChatCreated
  node["migrateToChatId"].parseNode        res.migrateToChatId
  node["migrateFromChatId"].parseNode      res.migrateFromChatId
  node["pinnedMessage"].parseNode          res.pinnedMessage

proc parseNode(node : JsonNode, res : var Update) =
  node.assertKind JObject
  node["update_id"].parseNode           res.update_id
  node["message"].parseNode            res.message
  node["edited_message"].parseNode      res.edited_message
  node["channel_post"].parseNode        res.channel_post
  node["edited_channel_post"].parseNode  res.edited_channel_post
  #inlineQuery        : Option[InlineQuery]
  #chosenInlineResult : Option[ChosenInlineResult]
  #callbackQuery      : Option[CallbackQuery]

proc parseUpdates*(node : JsonNode) : seq[Update] =
  #try:
    node.parseNode result
  #except:
  #  echo getCurrentExceptionMsg()
  #  result = @[]

proc parseUser*(node : JsonNode) : User =
  node.parseNode result
