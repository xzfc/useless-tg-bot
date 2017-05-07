from opinions.base import Base
from opinions.parser import parse, parse_about
from telegram.ext import Filters, MessageHandler, CommandHandler
from utils import print_exceptions
import cgi

class UnknownUser(Exception):
    def __init__(self, name):
        self.name = name

class Renderer:
    @staticmethod
    def render_names(get_name, *uids):
        return cgi.escape(" и ".join(map(get_name, uids)))

    @staticmethod
    def render_about(get_name, request, results):
        if len(request) == 0:
            return "..."
        if len(results) == 0:
            return "Ещё никто ничего не говорил о %s!" % Renderer.render_names(get_name, *request)
        result = []
        for entry in results:
            result.append(cgi.escape(" и ".join(map(get_name, entry.subj_uids))))
            result.append(" — ")
            result.append(entry.text)
            result.append(" <i>(%s)</i>" %
                    Renderer.render_names(get_name, entry.author_uid))
            result.append("\n")
        return "".join(result)

    @staticmethod
    def render_done(get_name, old):
        if old is None:
            return "Записала!"
        else:
            return "Переписала!"

class Opinions:
    def __init__(self, bot):
        self._bot = bot
        self.db = Base(bot.db)
        bot.updater.dispatcher.add_handler(MessageHandler(Filters.text, self.handle), 2)
        bot.updater.dispatcher.add_handler(CommandHandler("about", self.handle_about), 3)

    @print_exceptions
    def handle(self, bot, update):
        p = None
        try:
            p = parse(self._get_id, update)
        except UnknownUser as e:
            self._do_not_know(update, e.name)
        if p is not None:
            old = self.db.add_opinion(*p)
            text = Renderer.render_done(self._get_name, old)
            update.message.reply_text(text, parse_mode="HTML")

    @print_exceptions
    def handle_about(self, bot, update):
        p = []
        try:
            p = parse_about(self._get_id, update)
        except UnknownUser as e:
            self._do_not_know(update, e.name)
            return
        p = list(set(p))
        results = self.db.search_by_subj_ids(update.message.chat.id, p)
        reply_text = Renderer.render_about(self._get_name, p, results)
        update.message.reply_text(reply_text, parse_mode="HTML")

    def _get_name(self, uid):
        return self._bot.plugins['ids'].get_by_uid(uid)[1]

    def _get_id(self, entity):
        if entity.type == 'text_mention':
            return entity.user.id
        if entity.type == 'mention' and entity.text.startswith('@'):
            user = self._bot.plugins['ids'].get_by_uname(entity.text[1:])
            if user == None:
                raise UnknownUser(entity.text)
            return user[0]

    def _do_not_know(self, update, name):
        if name is None:
            text = "Ничего не знаю!"
        else:
            text = "Не видела тут %s." % cgi.escape(name)
        update.message.reply_text(text, parse_mode="HTML")


    NAME = "opinions"

    HELP = """
        (ответ) "Ты — " {текст}
        <упоминание> " — " {текст}
        <упоминание> " и " <упоминание> " — " {текст}
        <упоминание> " + " <упоминание> " = " {текст}

        /opinions_of <упоминание>
        /about <упоминание>
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
