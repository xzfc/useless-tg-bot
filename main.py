from telegram.ext import Updater
from opinions import Opinions
from ids.base import Ids
import sys

import sqlite3

class Bot:
    def __init__(self):
        self.db = sqlite3.connect('example.db', check_same_thread = False)
        self.updater = Updater(sys.argv[1])
        self.plugins = {}

    def run(self):
        self.updater.start_polling()
        self.updater.idle()

    def add_plugin(self, Plugin):
        self.plugins[Plugin.NAME] = Plugin(self)

bot = Bot()
bot.add_plugin(Opinions)
bot.add_plugin(Ids)
bot.run()
