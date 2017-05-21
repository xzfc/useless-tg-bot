import db_sqlite
import sequtils
import options
import strutils
import telega/types
import telega/html

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

proc allRows(db: DbConn, query: SqlQuery,
             args : varargs[string, `$`]) : seq[Row] =
  return toSeq(db.fastRows(query, args))

proc optionalRow(db : DbConn, query : SqlQuery,
      args : varargs[string, `$`]) : Option[Row] =
  let a = db.allRows(query, args)
  if a.len() == 0:
    return none(Row)
  else:
    return some(a[0])

proc getNil(s : Option[string]): string =
  if s.isSome:
    return s.get
  else:
    return nil

proc putNil(s: string): Option[string] =
  if s.isNil or s.len == 0: # TODO: why NULL isn't nil?
    none(string)
  else:
    some(s)

proc get_0(row : Row) : auto = row[0]

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

proc init*(db : DbConn) =
  db.exec sql"""
    CREATE TABLE IF NOT EXISTS users (
      uid        INTEGER,
      first      TEXT,
      last       TEXT,
      uname      TEXT COLLATE NOCASE,
      PRIMARY KEY (uid)
    )"""
  db.exec sql"""
    CREATE TABLE IF NOT EXISTS chat_history (
      chat_id    INTEGER,
      author_uid INTEGER,
      text       TEXT
    )"""
  db.exec sql"""
    CREATE TABLE IF NOT EXISTS opinions (
      chat_id    INTEGER,
      author_uid INTEGER,
      subj_uid   INTEGER,
      text       TEXT,
      PRIMARY KEY (chat_id, author_uid, subj_uid)
    )"""

proc rememberUser*(db: DbConn, user: User) =
  if user.username.isSome:
    db.exec sql"""
              UPDATE users
                 SET uname = NULL
               WHERE uname == ?
            """,
            user.username.get
  db.exec sql"""
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
                              subjUid: int) : seq[OpinionRow] =
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
                                authorUid: int) : seq[OpinionRow] =
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
  db.exec(query, chatId, authorUid, subjUid, text)

proc forgetOpinion*(db: DbConn, chatId: int64,
                    authorUid, subjUid: int) =
  const query = sql"""
    DELETE FROM opinions
     WHERE chat_id = ?
       AND author_uid = ?
       AND subj_uid = ?
  """
  db.exec(query, chatId, authorUid, subjUid)

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
