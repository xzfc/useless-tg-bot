import sqlite3

class Base:
    def __init__(self, conn):
        self.conn = conn

    def setup(self):
        c = self.conn.cursor()
        c.execute('''CREATE TABLE opinion (
                       chat_id INTEGER,

                       author_uid INTEGER,
                       author_uname TEXT,

                       subj0_uid INTEGER,
                       subj1_uid INTEGER,
                       subj2_uid INTEGER,

                       subj0_uname TEXT,
                       subj1_uname TEXT,
                       subj2_uname TEXT,

                       text TEXT)''')
        self.conn.commit()

    def search_by_subj_uname(self, chat_id, uname):
        c = self.conn.cursor()
        c.execute('''SELECT text, author_uname FROM `opinion` where
                     chat_id = :chat_id and
                     (subj0_uname = :uname or 
                      subj1_uname = :uname or 
                      subj2_uname = :uname)
                  ''', {"chat_id": chat_id, "uname": uname})
        return c.fetchall()

    def search_by_subj_ids(self, chat_id, subj_ids):
        if len(subj_ids) not in [1, 2, 3]:
            return []
        subj_ids = sorted(subj_ids)
        c = self.conn.cursor()
        if len(subj_ids) == 1:
            c.execute('''SELECT text, author_uname FROM `opinion` where
                         chat_id = :chat_id and
                         (subj0_uid = :id0 or 
                          subj1_uid = :id0 or 
                          subj2_uid = :id0)''',
                      {"chat_id": chat_id,
                       "id0": subj_ids[0]})
        elif len(subj_ids) == 2:
            c.execute('''SELECT text, author_uname FROM `opinion` where
                         chat_id = :chat_id and
                         (subj0_uid = :id0 and subj1_uid = :id1 or 
                          subj0_uid = :id0 and subj2_uid = :id1 or 
                          subj1_uid = :id0 and subj2_uid = :id1)''',
                      {"chat_id": chat_id,
                       "id0": subj_ids[0],
                       "id1": subj_ids[1]})
        elif len(subj_ids) == 3:
            c.execute('''SELECT text, author_uname FROM `opinion` where
                         chat_id = :chat_id and
                         (subj0_uid = :id0 and
                          subj1_uid = :id1 and
                          subj2_uid = :id2)''',
                      {"chat_id": chat_id,
                       "id0": subj_ids[0],
                       "id1": subj_ids[1],
                       "id2": subj_ids[2]})
        return c.fetchall()

    def search_by_text(self, text):
        # TODO
        pass

    def add_opinion(self, chat_id, author_uid, author_uname, subjs, text):
        if len(subjs) > 3 or len(subjs) == 0:
            return
        c = self.conn.cursor()
        subj_uids = [subj[0] for subj in subjs]
        subj_uids.sort()
        subj_uids += [None] * (3 - len(subjs))
        subj_unames = [subj[1] for subj in subjs]
        subj_unames += [None] * (3 - len(subjs))
        c.execute('''INSERT INTO opinion VALUES (?,?,?, ?,?,?, ?,?,?, ?)''',
                  [chat_id, author_uid, author_uname] +
                  subj_uids + subj_unames + [text])
        self.conn.commit()
