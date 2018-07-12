import options

type
  Update* = object
    updateId                   *: int32
    message                    *: Option[Message]
    editedMessage              *: Option[Message]
    channelPost                *: Option[Message]
    editedChannelPost          *: Option[Message]
    inlineQuery                *: Option[InlineQuery]
    chosenInlineResult         *: Option[ChosenInlineResult]
    callbackQuery              *: Option[CallbackQuery]
    shippingQuery              *: Option[ShippingQuery]
    preCheckoutQuery           *: Option[PreCheckoutQuery]

  User* = object
    id                         *: int32
    isBot                      *: bool
    firstName                  *: string
    lastName                   *: Option[string]
    username                   *: Option[string]
    languageCode               *: Option[string]

  ChatKind* = enum
    cPrivate
    cGroup
    cSupergroup
    cChannel
    cUnknown

  Chat* = object
    id                         *: int64
    kind                       *: ChatKind
    title                      *: Option[string]
    username                   *: Option[string]
    firstName                  *: Option[string]
    lastName                   *: Option[string]
    allMembersAreAdministrators*: Option[bool]
    photo                      *: Option[ChatPhoto]
    description                *: Option[string]
    inviteLink                 *: Option[string]
    pinnedMessage              *: ref Message
    stickerSetName             *: Option[string]
    canSetStickerSet           *: Option[bool]

  Message* = object
    messageId                  *: int32
    fromUser                   *: Option[User]
    date                       *: int32
    chat                       *: Chat
    forwardFrom                *: Option[User]
    forwardFromChat            *: Option[Chat]
    forwardFromMessageId       *: Option[int32]
    forwardSignature           *: Option[string]
    forwardDate                *: Option[int32]
    replyToMessage             *: ref Message
    editDate                   *: Option[int32]
    mediaGroupId               *: Option[string]
    authorSignature            *: Option[string]
    text                       *: Option[string]
    entities                   *: Option[seq[MessageEntity]]
    captionEntities            *: Option[seq[MessageEntity]]
    audio                      *: Option[Audio]
    document                   *: Option[Document]
    game                       *: Option[Game]
    photo                      *: Option[seq[PhotoSize]]
    sticker                    *: Option[Sticker]
    video                      *: Option[Video]
    voice                      *: Option[Voice]
    videoNote                  *: Option[VideoNote]
    caption                    *: Option[string]
    contact                    *: Option[Contact]
    location                   *: Option[Location]
    venue                      *: Option[Venue]
    newChatMembers             *: Option[seq[User]]
    leftChatMember             *: Option[User]
    newChatTitle               *: Option[string]
    newChatPhoto               *: Option[seq[PhotoSize]]
    migrateToChatId            *: Option[int64]
    migrateFromChatId          *: Option[int64]
    pinnedMessage              *: ref Message
    invoice                    *: Option[Invoice]
    successfulPayment          *: Option[SuccessfulPayment]

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
    offset                     *: int32
    length                     *: int32
    case kind                  *: MessageEntityType
    of meTextLink:
      url                      *: string
    of meTextMention:
      user                     *: User
    else:
      discard

  PhotoSize* = object
    fileId                     *: string
    width                      *: int32
    height                     *: int32
    fileSize                   *: Option[int32]

  Audio* = object
    fileId                     *: string
    duration                   *: int32
    performer                  *: Option[string]
    title                      *: Option[string]
    mimeType                   *: Option[string]
    fileSize                   *: Option[int32]

  Document* = object
    fileId                     *: string
    thumb                      *: Option[PhotoSize]
    fileName                   *: Option[string]
    mimeType                   *: Option[string]
    fileSize                   *: Option[int32]

  Video* = object
    fileId                     *: string
    width                      *: int32
    height                     *: int32
    duration                   *: int32
    thumb                      *: Option[PhotoSize]
    mimeType                   *: Option[string]
    fileSize                   *: Option[int32]

  Voice* = object
    fileId                     *: string
    duration                   *: int32
    mimeType                   *: Option[string]
    fileSize                   *: Option[int32]

  VideoNote* = object
    fileId                     *: string
    length                     *: int32
    duration                   *: int32
    thumb                      *: Option[PhotoSize]
    fileSize                   *: Option[int32]

  Contact* = object
    phoneNumber                *: string
    firstName                  *: string
    lastName                   *: Option[string]
    userId                     *: Option[int32]

  Location* = object
    longitude                  *: float
    latitude                   *: float

  Venue* = object
    location                   *: Location
    title                      *: string
    address                    *: string
    foursquareId               *: Option[string]

  CallbackQuery* = object
    id                         *: string
    fromUser                   *: User
    message                    *: Option[Message]
    inlineMessageId            *: Option[string]
    chatInstance               *: string
    data                       *: Option[string]
    gameShortName              *: Option[string]

  ChatPhoto* = object
    smallFileId                *: string
    bigFileId                  *: string

  Sticker* = object
    fileId                     *: string
    width                      *: int32
    height                     *: int32
    thumb                      *: Option[PhotoSize]
    emoji                      *: Option[string]
    setName                    *: Option[string]
    maskPosition               *: Option[MaskPosition]
    fileSize                   *: Option[int32]

  MaskPosition* = object
    point                      *: string
    xShift                     *: float
    yShift                     *: float
    scale                      *: float

  InlineQuery* = object
    id                         *: string
    fromUser                   *: User
    location                   *: Option[Location]
    query                      *: string
    offset                     *: string

  ChosenInlineResult* = object
    resultId                   *: string
    fromUser                   *: User
    location                   *: Option[Location]
    inlineMessageId            *: Option[string]
    query                      *: string

  Invoice* = object
    title                      *: string
    description                *: string
    startParameter             *: string
    currency                   *: string
    totalAmount                *: int32

  ShippingAddress* = object
    countryCode                *: string
    state                      *: string
    city                       *: string
    streetLine1                *: string
    streetLine2                *: string
    postCode                   *: string

  OrderInfo* = object
    name                       *: Option[string]
    phoneNumber                *: Option[string]
    email                      *: Option[string]
    shippingAddress            *: Option[ShippingAddress]

  SuccessfulPayment* = object
    currency                   *: string
    totalAmount                *: int32
    invoicePayload             *: string
    shippingOptionId           *: Option[string]
    orderInfo                  *: Option[OrderInfo]
    telegramPaymentChargeId    *: string
    providerPaymentChargeId    *: string

  ShippingQuery* = object
    id                         *: string
    fromUser                   *: User
    invoicePayload             *: string
    shippingAddress            *: ShippingAddress

  PreCheckoutQuery* = object
    id                         *: string
    fromUser                   *: User
    currency                   *: string
    totalAmount                *: int32
    invoicePayload             *: string
    shippingOptionId           *: Option[string]
    orderInfo                  *: Option[OrderInfo]

  Game* = object
    title                      *: string
    description                *: string
    photo                      *: seq[PhotoSize]
    text                       *: Option[string]
    textEntities               *: Option[seq[MessageEntity]]
    animation                  *: Option[Animation]

  Animation* = object
    fileId                     *: string
    thumb                      *: Option[PhotoSize]
    fileName                   *: Option[string]
    mimeType                   *: Option[string]
    fileSize                   *: Option[int32]

  GameHighScore* = object
    position                   *: int32
    user                       *: User
    score                      *: int32
