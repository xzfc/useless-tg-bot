import asyncdispatch
import httpclient
import json
import ./parser
import ./types

type Telega* = ref object
  token     : string
  update_id : int32

type TelegaOption[T] = object
  case ok: bool
  of true:
    result: T
  of false:
    code        : int
    description : string

proc getErrorText[T](t: TelegaOption[T]): string =
  return t.description & " (code " & $t.code & ")"

proc getResult[T](t: TelegaOption[T]): T =
  if t.ok:
    return t.result
  else:
    raise newException(Exception, t.getErrorText)

const BASE_URL = "https://api.telegram.org/bot"

proc telegramMethod*(this: Telega,
                     name: string,
                     data: MultipartData
                     ): Future[TelegaOption[JsonNode]] {.async.} =
  let client = newAsyncHttpClient()
  let url = BASE_URL & this.token & "/" & name
  let resp = await client.post(url, multipart=data)
  let res = parseJson(resp.body)
  client.close()

  if res["ok"].getBVal:
    result.ok = true
    result.result = res["result"]
  else:
    result.ok = false
    result.code = res["error_code"].getNum.int
    result.description = res["description"].getStr

proc newTelega*(token : string) : Telega =
  new(result)
  result.token = token
  result.update_id = 0

proc getMe*(this : Telega) : Future[User] {.async.} =
  let reply = await telegramMethod(this, "getMe", nil)
  return reply.getResult.parseUser

proc getUpdates*(this: Telega,
                 timeout: int = 10) : Future[seq[Update]] {.async.} =
  var form = newMultiPartData()
  form["offset"] = $this.update_id
  form["timeout"] = $timeout
  let reply = await telegramMethod(this, "getUpdates", form)
  if reply.ok:
    let parsedReply = reply.result.parseUpdates
    for update in parsedReply:
      this.update_id = update.update_id+1
    return parsedReply
  else:
    echo "getUpdates: " & reply.getErrorText
    return @[]

proc sendMessage*(this: Telega,
                  chatId: int64,
                  text: string,
                  parseMode: string = "",
                  disableWebPagePreview: bool = false,
                  replyToMessageId: int = 0
            ) : Future[bool] {.async.} =
  var form = newMultiPartData()
  form["chat_id"] = $chatId
  form["text"] = text
  if parseMode.len != 0:
    form["parse_mode"] = parseMode
  if disableWebPagePreview:
    form["disable_web_page_preview"] = $true
  if replyToMessageId != 0:
    form["reply_to_message_id"] = $replyToMessageId
  let reply = await telegramMethod(this, "sendMessage", form)
  if reply.ok:
    return true
  else:
    echo "sendMessage: " & reply.getErrorText
    return false

proc reply*(this: Telega,
            msg: Message,
            text: string,
            parseMode: string = "",
            disableWebPagePreview: bool = false
           ): Future[bool] =
  this.sendMessage(msg.chat.id,
                   text,
                   parseMode,
                   disableWebPagePreview,
                   msg.message_id.int)
