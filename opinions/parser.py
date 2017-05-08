import parser

PREFIXES = [" — ", " -- "]

def is_mention(entity):
    return entity.type in ['mention', 'text_mention']

def is_and(entity):
    return entity.type in ['plain'] and \
           entity.text.strip() == 'и'

def starts_with_prefix(entity):
    return entity.type in ['plain'] and \
           any(map(entity.text.startswith, PREFIXES))

def get_text(message):
    for prefix in PREFIXES:
        if message[0].text.startswith(prefix):
            message[0].text = message[0].text[len(prefix):]
            break
    return parser.serialize_to_html(message)

def parse(get_id, update):
    chat_id = update.message.chat.id
    author_uid = update.message.from_user.id
    mode = subjs = text = None

    message = parser.parse(update.message)

    # <mention> " — " {text}
    if len(message) >= 2 and \
       is_mention(message[0]) and \
       starts_with_prefix(message[1]):
        mode = 'add'
        subjs = [get_id(message[0])]
        text = get_text(message[1:])

    # <mention> " and " <mention> " — " {text}
    if len(message) >= 4 and \
       is_mention(message[0]) and \
       is_and(message[1]) and \
       is_mention(message[2]) and \
       starts_with_prefix(message[3]):
        mode = 'add'
        subjs = [get_id(message[0]), get_id(message[2])]
        text = get_text(message[3:])

    if subjs is not None:
        return (chat_id, author_uid, subjs, text)

def parse_about(get_id, update):
    result = []
    for entity in parser.parse(update.message):
        if entity.type in ['mention', 'text_mention']:
            result.append(get_id(entity))
    return result
