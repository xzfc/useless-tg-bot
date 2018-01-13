import options

type
  ChatKind* = enum
    cPrivate
    cGroup
    cSupergroup
    cChannel
    cUnknown

  Chat* = object
    id                          *: int64
    kind                        *: ChatKind
    title                       *: Option[string]
    username                    *: Option[string]
    firstName                   *: Option[string]
    lastName                    *: Option[string]
    allMembersAreAdministrators *: Option[bool]

  User* = object
    id           *: int32
    isBot        *: bool
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
    setName  *: Option[string]
    fileSize *: Option[uint]

  Document* = object
    fileId   *: string
    thumb    *: Option[PhotoSize]
    fileName *: Option[string]
    mimeType *: Option[string]
    fileSize *: Option[uint]

  MessageEntityType* = enum
    meMention
    meHashtag
    meBotCommand
    meUrl
    meEmail
    meBold
    meItalic
    meCode
    mePre
    meTextLink
    meTextMention
    meUnknown

  MessageEntity* = object
    offset *: int32
    length *: int32
    case kind *: MessageEntityType
    of meTextLink:
      url  *: string
    of meTextMention:
      user *: User
    else:
      discard

  Message* = object
    messageId             *: int32
    fromUser              *: Option[User]
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
    newChatMembers        *: Option[seq[User]]
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
