from telegram.ext import Filters, MessageHandler
from utils import print_exceptions

import traceback

class Base:
    def __init__(self, conn):
        self._conn = conn
        self.setup()

    def setup(self):
        c = self._conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS ids (
                       chat_id INTEGER,
                       uid INTEGER,
                       name TEXT,
                       uname TEXT,
                       PRIMARY KEY (chat_id, uid));
                       
                    ''')
        self._conn.commit()

    def save(self, chat_id, uid, name, uname):
        c = self._conn.cursor()
        c.execute('''INSERT OR REPLACE INTO ids VALUES (?, ?, ?, ?)''',
                  (chat_id, uid, name, uname))
        self._conn.commit()

class Ids:
    def __init__(self, bot):
        self._db = Base(bot.db)
        bot.updater.dispatcher.add_handler(MessageHandler(None, self.handle), 1)

    @print_exceptions
    def handle(self, bot, update):
        self._save(update.message)
        self._save(update.message.reply_to_message)

    def _save(self, message):
        if message is None:
            return

        chat_id = message.chat.id
        name = message.from_user.first_name
        if message.from_user.last_name:
            name += ' ' + message.from_user.last_name
        uname = message.from_user.username or None
        uid = message.from_user.id

        self._db.save(chat_id, uid, name, uname)

        print("Name: %s" % name)
        print("Username: %s" % uname)
        print("Chat ID: %d" % chat_id)
        print("User ID: %d" % uid)

    NAME = "ids"


def parse(update):
    pass
