import ./db_sqlite_extras
import db_sqlite
import options
import sequtils
import strutils
import telega/html
import telega/types

type
  OpinionRow* = object
    chat_id *: int64
    author  *: User
    subj    *: User
    text    *: string
  OpinionRatingRow* = object
    user     *: User
    asAuthor *: uint
    asSubj   *: uint
  MarkovNextRow* = object
    word  *: string
    count *: uint

proc allRows(db: DbConn, query: SqlQuery,
             args: varargs[DbValue, dbValue]): seq[Row] =
  return toSeq(db.fastRowsEx(query, args))

proc optionalRow(db: DbConn, query: SqlQuery,
      args: varargs[DbValue, dbValue]): Option[Row] =
  let a = db.allRows(query, args)
  if a.len() == 0:
    return none(Row)
  else:
    return some(a[0])

proc getNil(s: Option[string]): string =
  if s.isSome:
    return s.get
  else:
    return nil

proc putNil(s: string): Option[string] =
  if s.isNil or s.len == 0: # TODO: why NULL isn't nil?
    none(string)
  else:
    some(s)

proc get_0(row: Row): string = row[0]

proc get_0int(row: Row): int = row[0].parseInt

proc getUser(row: Row, idx: int): User =
  result.id         = row[idx+0].parseInt.int32
  result.first_name = row[idx+1]
  result.last_name  = row[idx+2].putNil
  result.username   = row[idx+3].putNil

proc getUser(row: Row): User =
  getUser(row, 0)

proc getOpinionRow(r: Row): OpinionRow =
  result.chat_id = r[0].parseInt.int64
  result.author  = getUser(r, 1)
  result.subj    = getUser(r, 5)
  result.text    = r[9]

proc getOpinionRatingRow(r: Row): OpinionRatingRow =
  result.user     = getUser(r, 0)
  result.asAuthor = r[4].parseUint
  result.asSubj   = r[5].parseUint

proc getMarkovNextRow(r: Row): MarkovNextRow =
  result.word  = if r[0].len == 0: nil else: r[0]
  result.count = r[1].parseUint

proc init*(db: DbConn) =
  db.execEx sql"""
    CREATE TABLE IF NOT EXISTS users (
      uid        INTEGER,
      first      TEXT,
      last       TEXT,
      uname      TEXT COLLATE NOCASE,
      PRIMARY KEY (uid)
    )"""
  db.execEx sql"""
    CREATE TABLE IF NOT EXISTS chat_history (
      chat_id    INTEGER,
      author_uid INTEGER,
      text       TEXT
    )"""
  db.execEx sql"""
    CREATE TABLE IF NOT EXISTS opinions (
      chat_id    INTEGER,
      author_uid INTEGER,
      subj_uid   INTEGER,
      text       TEXT,
      PRIMARY KEY (chat_id, author_uid, subj_uid)
    )"""
  db.execEx sql"""
    CREATE TABLE IF NOT EXISTS markov (
      chat_id    INTEGER,
      word_from  TEXT,
      word_to    TEXT,
      count      INTEGER,
      PRIMARY KEY (chat_id, word_from, word_to)
    )"""
  db.execEx sql"""
    CREATE TABLE IF NOT EXISTS last_user_message (
      chat_id    INTEGER,
      user_id    INTEGER,
      message_id INTEGER,
      PRIMARY KEY (chat_id, user_id)
    )"""

proc rememberUser*(db: DbConn, user: User) =
  if user.username.isSome:
    db.execEx sql"""
                UPDATE users
                   SET uname = NULL
                 WHERE uname == ?
              """,
              user.username.get
  db.execEx sql"""
              INSERT OR REPLACE
                INTO users
              VALUES (?, ?, ?, ?)
            """,
            user.id,
            user.first_name,
            user.last_name.getNil,
            user.username.getNil

proc searchUserByUid*(db: DbConn, uid: int32): Option[User] =
  let query = sql"""
    SELECT *
      FROM users
     WHERE uid = ?
     LIMIT 1
  """
  return db.optionalRow(query, uid).map(getUser)

proc searchUserByUname*(db: DbConn, uname: string): Option[User] =
  let query = sql"""
    SELECT *
      FROM users
     WHERE uname = ?
     LIMIT 1
  """
  return db.optionalRow(query, uname).map(getUser)

proc searchOpinionsBySubjUid*(db: DbConn, chatId: int64,
                              subjUid: int): seq[OpinionRow] =
  const query = sql"""
    SELECT o.chat_id, a.*, s.*, o.text
      FROM opinions AS o
           INNER JOIN users a ON a.uid = o.author_uid
           INNER JOIN users s ON s.uid = o.subj_uid
     WHERE o.chat_id = ?
       AND o.subj_uid = ?
  """
  return db.allRows(query, chatId, subjUid).map(getOpinionRow)

proc searchOpinionsByAuthorUid*(db: DbConn, chatId: int64,
                                authorUid: int): seq[OpinionRow] =
  const query = sql"""
    SELECT o.chat_id, a.*, s.*, o.text
      FROM opinions AS o
           INNER JOIN users AS a ON a.uid = o.author_uid
           INNER JOIN users AS s ON s.uid = o.subj_uid
     WHERE o.chat_id = ?
       AND o.author_uid = ?
  """
  return db.allRows(query, chatId, authorUid).map(getOpinionRow)

proc searchOpinionsRating*(db: DbConn, chatId: int64): seq[OpinionRatingRow] =
  const query = sql"""
    SELECT u.*, IFNULL(a.c, 0) AS cnt_a, IFNULL(s.c, 0) AS cnt_s
      FROM users AS u

           LEFT JOIN (SELECT author_uid AS uid, count() AS c
                        FROM opinions
                       WHERE chat_id = ?
                       GROUP BY author_uid)
              AS a
              ON a.uid = u.uid
         
           LEFT JOIN (SELECT subj_uid AS uid, count() AS c
                        FROM opinions
                       WHERE chat_id = ?
                       GROUP BY subj_uid)
                  AS s
                  ON s.uid = u.uid

    WHERE cnt_a + cnt_s != 0
    ORDER BY cnt_a + cnt_s*2 DESC
  """
  return db.allRows(query, chatId, chatId).map(getOpinionRatingRow)

proc rememberOpinion*(db: DbConn, chatId: int64,
                      authorUid, subjUid: int,
                      text: string) =
  const query = sql"""
    INSERT OR REPLACE INTO opinions
    VALUES (?, ?, ?, ?)
  """
  db.execEx(query, chatId, authorUid, subjUid, text)

proc forgetOpinion*(db: DbConn, chatId: int64,
                    authorUid, subjUid: int) =
  const query = sql"""
    DELETE FROM opinions
     WHERE chat_id = ?
       AND author_uid = ?
       AND subj_uid = ?
  """
  db.execEx(query, chatId, authorUid, subjUid)

proc searchOpinion*(db: DbConn, chatId: int64,
                    authorUid, subjUid: int): Option[OpinionRow] =
  const query = sql"""
    SELECT o.chat_id, a.*, s.*, o.text
      FROM opinions AS o
           INNER JOIN users a ON a.uid = o.author_uid
           INNER JOIN users s ON s.uid = o.subj_uid
     WHERE o.chat_id = ?
       AND o.author_uid = ?
       AND o.subj_uid = ?
     LIMIT 1
  """
  return db.optionalRow(query, chatId, authorUid, subjUid).map(getOpinionRow)


proc rememberMarkov*(db: DbConn, chatId: int64, wordFrom, wordTo: string) =
  const query1 = sql"""
    INSERT OR IGNORE
      INTO markov
    VALUES (?, ?, ?, 0)
  """
  const query2 = sql"""
    UPDATE markov
       SET count = count + 1
     WHERE chat_id = ?
       AND word_from = ?
       AND word_to = ?
  """
  db.execEx(query1, chatId, wordFrom, wordTo)
  db.execEx(query2, chatId, wordFrom, wordTo)

proc markovGetNext*(db: DbConn, chatId: int64, wordFrom: string
                   ): seq[MarkovNextRow] =
  const query = sql"""
    SELECT word_to, count
      FROM markov
     WHERE chat_id = ?
       AND word_from = ?
  """
  db.allRows(query, chatId, wordFrom).map(getMarkovNextRow)

################################################################################

proc rememberLastUserMessage*(db: DbConn, chatId: int64, userId: int,
                              messageId: int) =
  const query = sql"""
    INSERT OR REPLACE
      INTO last_user_message
    VALUES (?, ?, ?)
  """
  db.execEx(query, chatId, userId, messageId)

proc getLastUserMessage*(db: DbConn, chatId: int64, userId: int): Option[int] =
  const query = sql"""
    SELECT message_id
      FROM last_user_message
     WHERE chat_id = ?
       AND user_id = ?
  """
  db.optionalRow(query, chatId, userId).map(get_0int)
