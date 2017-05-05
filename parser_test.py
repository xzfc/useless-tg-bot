from parser import parse, serialize
import json
from telegram import MessageEntity, Message

def simple_message(text, entities):
    return Message(
            message_id = 0,
            from_user = None,
            date = None,
            chat = None,
            text = text,
            entities = entities,
            )

def compare_messages(a, b):
    a = json.dumps(a.to_dict(), sort_keys = True)
    b = json.dumps(b.to_dict(), sort_keys = True)
    return a == b

def equaled(msg):
    return simple_message(*(serialize(parse(msg))))


test_message1 = simple_message(
        "/hello foo @reiimu_bot bar Jerky baz",
        [
            MessageEntity(type="bot_command", offset=0, length=6),
            MessageEntity(type="mention", offset=11, length=11),
            MessageEntity(type="text_mention", offset=27, length=5, user=None),
        ])

test_message2 = simple_message(
        "/hello f𝓮 @reiimu_bot bar Jerky baz",
        [
            MessageEntity(type="bot_command", offset=0, length=6),
            MessageEntity(type="mention", offset=11, length=11),
            MessageEntity(type="text_mention", offset=27, length=5, user=None),
        ])

print("Should be True:", compare_messages(test_message1, equaled(test_message1)))
print("Should be True:", compare_messages(test_message2, equaled(test_message2)))
print("Should be True:", parse(test_message2)[1] )
