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
                       uid INTEGER,
                       name TEXT,
                       uname TEXT,
                       PRIMARY KEY (uid));
                    ''')
        self._conn.commit()

    def save(self, uid, name, uname):
        c = self._conn.cursor()
        c.execute('''INSERT OR REPLACE INTO ids VALUES (?, ?, ?)''',
                  (uid, name, uname))
        self._conn.commit()

    def get_by_uname(self, uname):
        c = self._conn.cursor()
        c.execute('''SELECT * FROM `ids` WHERE uname = ?''', (uname,))
        return c.fetchone()

    def get_by_uid(self, uid):
        c = self._conn.cursor()
        c.execute('''SELECT * FROM `ids` WHERE uid = ?''', (uid,))
        return c.fetchone()

class Ids:
    def __init__(self, bot):
        self._db = Base(bot.db)
        bot.updater.dispatcher.add_handler(MessageHandler(None, self.handle), 1)

    @print_exceptions
    def handle(self, bot, update):
        self._save(update.message)
        self._save(update.message.reply_to_message)

    def get_by_uname(self, uname):
        return self._db.get_by_uname(uname)

    def get_by_uid(self, uid):
        return self._db.get_by_uid(uid)

    def _save(self, message):
        if message is None:
            return
        name = message.from_user.first_name
        if message.from_user.last_name:
            name += ' ' + message.from_user.last_name
        uname = message.from_user.username or None
        uid = message.from_user.id

        self._db.save(uid, name, uname)

    NAME = "ids"


def parse(update):
    pass
