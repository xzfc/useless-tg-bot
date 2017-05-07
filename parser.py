from telegram import Message, MessageEntity
import cgi

class MyMessageEntity:
    def __init__(self, type, text, url=None, user=None):
        self.type = type
        self.text = text
        self.url = url
        self.user = user
    def duplicate(self):
        return MyMessageEntity(self.type, self.text, self.url, self.user)
    def __str__(self):
        return "«%s» (%s)" % (self.text, self.type)
    PLAIN = 'plain'

def parse(message):
    result = []
    pos = 0
    message_text = message.text.encode('utf-16-le')
    for entity in message.entities + [None]:
        if entity is not None:
            start = entity.offset
            end = entity.offset + entity.length
        else:
            start = end = len(message_text) // 2

        if pos != start:
            entity_text = message_text[pos*2: start*2].decode('utf-16-le')
            result.append(MyMessageEntity(MyMessageEntity.PLAIN, entity_text))
        if entity is not None:
            entity_text = message_text[start*2: end*2].decode('utf-16-le')
            result.append(MyMessageEntity(entity.type, entity_text, entity.url, entity.user))
            pos = end
    return result

def serialize(entities):
    result_entities = []
    result_text = "".join((e.text for e in entities))
    pos = 0
    for entity in entities:
        length = len(entity.text.encode('utf-16-le')) // 2
        if entity.type != MyMessageEntity.PLAIN:
            result_entities.append(MessageEntity(type = entity.type,
                offset = pos,
                length = length,
                url = entity.url,
                user = entity.user))
        pos += length
    return result_text, result_entities

def serialize_to_html(entities):
    result = []
    for entity in entities:
        text = cgi.escape(entity.text)
        if entity.type == MessageEntity.TEXT_LINK:
            text = '<a href="{}">{}</a>'.format(entity.url, text)
        elif entity.type == MessageEntity.BOLD:
            text = '<b>{}</b>'.format(text)
        elif entity.type == MessageEntity.ITALIC:
            text = '<i>{}</i>'.format(text)
        elif entity.type == MessageEntity.CODE:
            text = '<code>{}</code>'.format(text)
        elif entity.type == MessageEntity.PRE:
            text = '<pre>{}</pre>'.format(text)
        result.append(text)
    return "".join(text)
