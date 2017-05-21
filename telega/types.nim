import options

type
  Chat* = object
    id*         : int64
    #type_      : ChatType.ChatType
    title*      : Option[string]
    username*   : Option[string]
    first_name* : Option[string]
    last_name*  : Option[string]
    allMembersAreAdministrators* : Option[bool]

  User* = object
    id*         : int32
    first_name* : string
    last_name*  : Option[string]
    username*   : Option[string]

  MessageEntityType* = enum
    metMention
    metHashtag
    metBotCommand
    metUrl
    metEmail
    metBold
    metItalic
    metCode
    metPre
    metTextLink
    metTextMention
    metUnknown

  MessageEntity* = object
    offset *: int32
    length *: int32
    case type0 *: MessageEntityType
    of metTextLink:
      url  *: string
    of metTextMention:
      user *: User
    else:
      discard

  Message* = object
    message_id               *: int32
    from0                    *: Option[User]
    date                     *: int32
    chat                     *: Chat
    forward_from             *: Option[User]
    forward_from_chat        *: Option[Chat]
    forward_from_message_id  *: Option[int32]
    forward_date             *: Option[int32]
    reply_to_message         *: ref Message # Option[Message]
    edit_date                *: Option[int32]
    text                     *: Option[string]
    entities                 *: Option[seq[MessageEntity]]
    #audio                   *: Option[Audio]
    #document                *: Option[Document]
    #game                    *: Option[Game]
    #photo                   *: Option[seq[PhotoSize]]
    #sticker                 *: Option[Sticker]
    #video                   *: Option[Video]
    #voice                   *: Option[Voice]
    caption                  *: Option[string]
    #contact                 *: Option[Contact]
    #location                *: Option[Location]
    #venue                   *: Option[Venue]
    new_chat_member          *: Option[User]
    left_chat_member         *: Option[User]
    new_chat_title           *: Option[string]
    #newChatPhoto            *: Option[seq[PhotoSize]]
    delete_chat_photo        *: Option[bool]
    groupChatCreated         *: Option[bool]
    supergroupChatCreated    *: Option[bool]
    channelChatCreated       *: Option[bool]
    migrateToChatId          *: Option[int64]
    migrateFromChatId        *: Option[int64]
    pinnedMessage            *: ref Message

  Update* = object
    update_id           *: int32
    message             *: Option[Message]
    edited_message      *: Option[Message]
    channel_post        *: Option[Message]
    edited_channel_post *: Option[Message]
    #inlineQuery        *: Option[InlineQuery]
    #chosenInlineResult *: Option[ChosenInlineResult]
    #callbackQuery      *: Option[CallbackQuery]
