import sqlite3

class Entry:
    def __init__(self, chat_id, author_uid, text, subj_uids):
        self.chat_id = chat_id
        self.author_uid = author_uid
        self.text = text
        self.subj_uids = subj_uids

    @staticmethod
    def make(chat_id, author_uid, text, subj0_uid, subj1_uid, subj2_uid):
        subj_uids = [subj0_uid, subj1_uid, subj2_uid]
        subj_uids = [i for i in subj_uids if i != 0]
        return Entry(chat_id, author_uid, text, subj_uids)

select = '''SELECT * FROM `opinion` WHERE '''

class Base:
    def __init__(self, conn):
        self.conn = conn
        self._setup()

    def _setup(self):
        c = self.conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS `opinion` (
                       chat_id INTEGER,
                       author_uid INTEGER,
                       text TEXT,

                       subj0_uid INTEGER,
                       subj1_uid INTEGER,
                       subj2_uid INTEGER,

                       PRIMARY KEY (chat_id, author_uid,
                                    subj0_uid, subj1_uid, subj2_uid)
                       )''')
        self.conn.commit()

    def search_by_subj_uname(self, chat_id, uname):
        pass # TODO

    def search_by_subj_ids(self, chat_id, subj_ids):
        if len(subj_ids) not in [1, 2, 3]:
            return []
        subj_ids = sorted(subj_ids)
        c = self.conn.cursor()
        if len(subj_ids) == 1:
            c.execute(select + '''chat_id = :chat_id and
                                  (subj0_uid = :id0 or 
                                   subj1_uid = :id0 or 
                                   subj2_uid = :id0)''',
                      {"chat_id": chat_id,
                       "id0": subj_ids[0]})
        elif len(subj_ids) == 2:
            c.execute(select + '''chat_id = :chat_id and
                                  (subj0_uid = :id0 and subj1_uid = :id1 or 
                                   subj0_uid = :id0 and subj2_uid = :id1 or 
                                   subj1_uid = :id0 and subj2_uid = :id1)''',
                      {"chat_id": chat_id,
                       "id0": subj_ids[0],
                       "id1": subj_ids[1]})
        elif len(subj_ids) == 3:
            c.execute(select + '''chat_id = :chat_id and
                                  (subj0_uid = :id0 and
                                   subj1_uid = :id1 and
                                   subj2_uid = :id2)''',
                      {"chat_id": chat_id,
                       "id0": subj_ids[0],
                       "id1": subj_ids[1],
                       "id2": subj_ids[2]})
        return [Entry.make(*i) for i in c.fetchall()]

    def search_by_text(self, text):
        # TODO
        pass

    def add_opinion(self, chat_id, author_uid, subj_uids, text):
        if len(subj_uids) > 3 or len(subj_uids) == 0:
            return
        c = self.conn.cursor()
        subj_uids = sorted(subj_uids) + [0] * (3 - len(subj_uids))
        c.execute('''SELECT * from `opinion`
                     WHERE chat_id = ? AND author_uid = ? AND
                     `subj0_uid` = ? AND `subj1_uid` = ? AND `subj2_uid` = ?
                     ''',
                  [chat_id, author_uid] + subj_uids)
        old = c.fetchone()
        if old:
            old = Entry.make(*old)
        c.execute('''INSERT OR REPLACE INTO opinion VALUES (?,?,?, ?,?,?)''',
                  [chat_id, author_uid, text] + subj_uids)
        self.conn.commit()
        return old
