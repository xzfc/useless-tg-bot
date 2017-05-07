import parser

def strip_prefix(message, prefix):
    if message[0].text.startswith(prefix):
        message[0].text = message[0].text[len(prefix):]
    return parser.serialize_to_html(message)

def parse(get_id, update):
    chat_id = update.message.chat.id
    author_uid = update.message.from_user.id
    mode = subjs = text = None

    message = parser.parse(update.message)

    # <mention> " — " {text}
    if len(message) >= 2 and \
       message[0].type in ['mention', 'text_mention'] and \
       message[1].type == 'plain' and message[1].text.startswith(" — "):
        mode = 'add'
        subjs = [get_id(message[0])]
        text = strip_prefix(message[1:], " — ")

    # <mention> " and " <mention> " — " {text}
    if len(message) >= 4 and \
       message[0].type in ['mention', 'text_mention'] and \
       message[1].type in ['plain'] and message[1].text.strip() == "и" and \
       message[2].type in ['mention', 'text_mention'] and \
       message[3].type in ['plain'] and message[3].text.startswith(" — "):
        mode = 'add'
        subjs = [get_id(message[0]), get_id(message[2])]
        text = strip_prefix(message[3:], " — ")

    if subjs is not None:
        return (chat_id, author_uid, subjs, text)

def parse_about(get_id, update):
    result = []
    for entity in parser.parse(update.message):
        if entity.type in ['mention', 'text_mention']:
            result.append(get_id(entity))
    return result
