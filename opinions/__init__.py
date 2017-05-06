from opinions.base import Base
from opinions.parser import parse
from telegram.ext import Filters, MessageHandler
import parser

class Opinions:

    def __init__(self, bot):
        self.db = Base(bot.db)
        bot.updater.dispatcher.add_handler(MessageHandler(Filters.text, self.handle), 2)

    def handle(self, bot, update):
        message = parser.parse(update.message)
        p = parse(message)

    NAME = "opinions"

    HELP = """
        (ответ) "Ты — " {текст}
        <упоминание> " — " {текст}
        <упоминание> " и " <упоминание> " — " {текст}
        <упоминание> " + " <упоминание> " = " {текст}

        /opinions_of <упоминание>
        /about <упоминание>
        /about {часть имени}
        /apropos {часть текста}
        """


#base = Base(conn)
#base.setup()
#
#base.add_opinion(9, 1, 'J', [(1, 'jerky')], "jerky — джерки")
#base.add_opinion(9, 1, 'J', [(1, 'jerky'), (2, 'mc')], "jerky mc — джерки мак")
#base.add_opinion(9, 1, 'J', [(1, 'jerky'), (2, 'mc'), (3, 'jerkface')], "jerky mcjerkface — джерки макджеркфейс")
#
#for i in base.search_by_subj_ids(9, [1]):
#    print(i)
#print()
#
#for i in base.search_by_subj_uname(9, "mc"):
#    print(i)
#print()
