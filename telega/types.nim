import options

type
  ChatType* = enum
    ctPrivate
    ctGroup
    ctSupergroup
    ctChannel
    ctUnknown

  Chat* = object
    id                          *: int64
    `type`                      *: ChatType
    title                       *: Option[string]
    username                    *: Option[string]
    firstName                   *: Option[string]
    lastName                    *: Option[string]
    allMembersAreAdministrators *: Option[bool]

  User* = object
    id           *: int32
    is_bot       *: bool
    firstName    *: string
    lastName     *: Option[string]
    username     *: Option[string]
    languageCode *: Option[string]

  PhotoSize* = object
    fileId   *: string
    width    *: uint
    height   *: uint
    fileSize *: Option[uint]

  Sticker* = object
    fileId   *: string
    width    *: uint
    height   *: uint
    thumb    *: Option[PhotoSize]
    emoji    *: Option[string]
    set_name *: Option[string]
    fileSize *: Option[uint]

  Document* = object
    fileId   *: string
    thumb    *: Option[PhotoSize]
    fileName *: Option[string]
    mimeType *: Option[string]
    fileSize *: Option[uint]

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
    case `type` *: MessageEntityType
    of metTextLink:
      url  *: string
    of metTextMention:
      user *: User
    else:
      discard

  Message* = object
    messageId             *: int32
    `from`                *: Option[User]
    date                  *: int32
    chat                  *: Chat
    forwardFrom           *: Option[User]
    forwardFromChat       *: Option[Chat]
    forwardFromMessageId  *: Option[int32]
    forwardSignature      *: Option[string]
    forwardDate           *: Option[int32]
    replyToMessage        *: ref Message
    editDate              *: Option[int32]
    text                  *: Option[string]
    entities              *: Option[seq[MessageEntity]]
    #audio                *: Option[Audio]
    document              *: Option[Document]
    #game                 *: Option[Game]
    photo                 *: Option[seq[PhotoSize]]
    sticker               *: Option[Sticker]
    #video                *: Option[Video]
    #voice                *: Option[Voice]
    caption               *: Option[string]
    #contact              *: Option[Contact]
    #location             *: Option[Location]
    #venue                *: Option[Venue]
    newChatMember         *: Option[User] # undocumented
    newChatParticipant    *: Option[User] # undocumented
    newChatMembers        *: Option[seq[User]]
    leftChatParticipant   *: Option[User] # undocumented
    leftChatMember        *: Option[User]
    newChatTitle          *: Option[string]
    newChatPhoto          *: Option[seq[PhotoSize]]
    deleteChatPhoto       *: Option[bool]
    groupChatCreated      *: Option[bool]
    supergroupChatCreated *: Option[bool]
    channelChatCreated    *: Option[bool]
    migrateToChatId       *: Option[int64]
    migrateFromChatId     *: Option[int64]
    pinnedMessage         *: ref Message

  Update* = object
    updateId            *: int32
    message             *: Option[Message]
    editedMessage       *: Option[Message]
    channelPost         *: Option[Message]
    editedChannelPost   *: Option[Message]
    #inlineQuery        *: Option[InlineQuery]
    #chosenInlineResult *: Option[ChosenInlineResult]
    #callbackQuery      *: Option[CallbackQuery]
