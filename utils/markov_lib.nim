import ../sweet_options
import ndb/sqlite
import nre except toSeq
import random
import sequtils
import strutils except toLower
import sugar
import unicode

type
  Entry = object
    tokens: seq[string]
    next:   string
  Markov* = object
    db*: DbConn
    inTransaction*: bool

proc debug(s: string) {.tags:[WriteIOEffect].} =
  if s == "":
    stderr.writeLine ""
  else:
    stderr.writeLine "\e[2mMarkov: ", s, "\e[m"

proc maps(f:int, t: int, tmpl: string): string =
  map(toSeq(f..t), proc(i: int): string = tmpl % @[$i]).join

const rank = 6
  ## Rank of the Markov chain.
  ## I.e. only up to last `rank` tokens are taken into account in the process of
  ## next token generation.

proc rankFill[T](s: seq[T], val: T): seq[T] =
  result = s
  while result.len < rank:
    result.insert val

proc rankAdd[T](s: var seq[T], val: T) =
  s.add(val)
  if s.len > rank:
    s.delete(0, 0)

func sqr(i: int): int = i*i

let url_re = re"""(?x)
  (:? (:? ftp | https? ) :// )?
  [-a-zA-Z0-9@:%._\+~#=]{2,256}
  \.
  [a-z]{2,6}
  \b
  (?: [-a-zA-Z0-9@:%_\+.~#?&//=]* )
  """
let escapeRe = re"[\\\[\]]"

iterator tokenize*(s: string): string {.tags:[].} =
  ## Tokenize line.
  ## This function have following design goals:
  ## * Word and adjoining punctuation are separate tokens.
  ##   e.g. "Hello!" should be tokenized as ["Hello", "!"].
  ## * "..." and "?!" are a single token.
  ## * But "»." tokenized as two separate tokens.
  ## * Leading space is considered as part of the token.
  ##   Any non-zero number of whitespace characters (including tabs and
  ##   newlines) is replaced with one space.
  ## * Each of these is a single token:
  ##   * https://example.com/
  ##   * underscore_separated_words
  ##   * #hashtag
  ##   * @username
  ## * "$start" and "$end" should not be valid tokens since they are used in
  ##   this module as special values.
  let ss = s.replace(escapeRe, r"\$0").replace(urlRe, "[$0]")
  proc getClass(c: Rune): int =
    const sa = "0123456789@_#".toRunes
    if c.isAlpha or sa.contains c: return 0

    const sp = ",.!?".toRunes
    if sp.contains c: return 2

    if c.isWhiteSpace: return -1

    return 1

  var state = -3
  # States:
  #    2 punctuation ,.!?
  #    1 other
  #    0 alphanumerics and @_#
  #   -1 space
  #   -2 url
  #   -3 initial
  var escape = false
  var token = ""
  var haveSpace = false

  template yi =
    if state != -1 and state != -3:
      yield (if haveSpace: " " & token else: token)
    haveSpace = state == -1
    token = ""

  for c in ss.runes:
    var doEscape = false
    if escape:
      escape = false
      doEscape = true
    else:
      if c == Rune '\\':
        escape = true
        continue

    let cl = c.getClass

    if state == -2:
      if (c == Rune ']') and not doEscape:
        yi()
        state = -1
        continue
    else:
      if (c == Rune '[') and not doEscape:
        yi()
        state = -2
        continue
      if cl != state:
        yi()
        state = cl

    token &= c.toUTF8
  yi

iterator makeEntries(line: string): Entry {.tags:[].} =
  var r = Entry(next: "", tokens: @["$start"])
  for token in line.tokenize:
    r.next = token
    yield r
    r.tokens.rankAdd token.strip.toLower
  r.next = "$end"
  yield r

iterator initQueries: string {.tags:[],noSideEffect.} =
  yield
    "CREATE TABLE IF NOT EXISTS markov (\n" &
    "  chat_id    NUMBER NOT NULL,\n" &
    "  message_id NUMBER NOT NULL,\n" &
    "  next       TEXT NOT NULL,\n" &
    maps(1, rank, "  w${1}         TEXT,\n") &
    "  PRIMARY KEY(chat_id, message_id" & maps(1, rank, ", w$1") & ")\n" &
    ")"

  for i in 1..rank:
    yield
      "CREATE INDEX IF NOT EXISTS markov_i$1 ON markov (" % @[$i] &
      "\n chat_id" & maps(i, rank, ", w$1") & ", message_id)"

proc insert(db: DbConn, chatId: int, messageId: int, n: Entry
           ) {.tags:[ReadDbEffect,WriteDbEffect].} =
  const query = SqlQuery("""
    INSERT OR IGNORE INTO markov
    VALUES (?, ?, ?""" & maps(1, rank, ", ?") & ")")
  let args =
    @[chatId.dbValue, messageId.dbValue, n.next.dbValue] &
    map(n.tokens, dbValue).rankFill dbNilValue
  db.exec(query, @args)

proc selectNext1(db:DbConn, chatId: int, tokens: seq[string],
                 messageIds: seq[int]): seq[Row] {.tags:[ReadDbEffect].} =
  ## Select all possible next tokens.
  ## Requriments are strict: `tokens` are preceding tokens, `messageIds` are
  ## prohibited message ids.
  var query = "SELECT next, message_id FROM markov WHERE chat_id = ?"
  var args = @[chatId.dbValue]

  var n = rank - tokens.len + 1
  for w in tokens:
    query &= " AND w" & $n & " = ?"
    args &= w.dbValue
    n.inc
  if messageIds.len > 0:
    query &= "AND message_id NOT in(" &
             "?".repeat(messageIds.len).join(",") & ")"
    args &= map(messageIds, dbValue)
  return db.getAllRows(query.SqlQuery, @args)

proc selectNext(db: DbConn, chatId: int, tokens: seq[string],
                messageIds: seq[int], reverse: bool
               ): Option[(string, int, seq[string])]
                  {.tags:[ReadDbEffect,WriteIOEffect].} =
  ## Select random next token.
  ## Requriments are not strict. Loose them if there are no matching candidates:
  ## * When reverse:  use only a few first `tokens`.
  ## * Uness reverse: use only a few last `tokens`.
  ## * Ignore `messageIds`.
  for i in 0..1: # 0 - prohibit messageIds; 1 - ignore messageIds
    if i == 1 and messageIds.len == 0:
      continue
    let messageIdsD = if i == 0: messageIds.deduplicate else: @[]
    for n in 0..tokens.len-1:
      let tokensD = if reverse: tokens[0..^(n+1)] else: tokens[n..^1]
      let rows = db.selectNext1(chatId, tokensD, messageIdsD)
      if rows.len != 0:
        let row = rows[rand(rows.len-1)]
        debug "$1 $2 $3 -> $4" % @[
          (if i == 0: " " else: "/"),
          $rows.len,
          tokensD.join(" "),
          row[0].s
        ]
        return (row[0].s, row[1].i.int, tokensD).some

proc newMarkov*(dbPath: string): Markov {.tags:[DbEffect].} =
  result.db = open(dbPath, "", "", "")
  result.inTransaction = false
  for i in initQueries():
    result.db.exec i.SqlQuery

proc learn*(m: Markov, chatId: int, messageId: int, line: string,
            transaction: bool = true) {.tags:[ReadDbEffect,WriteDbEffect].} =
  if transaction:
    m.db.exec sql"BEGIN TRANSACTION"
  m.db.exec(sql"DELETE FROM markov WHERE chat_id = ? AND message_id = ?",
              chatId, messageId)
  for entry in line.makeEntries:
    m.db.insert(chatId, messageId, entry)
  if transaction:
    m.db.exec sql"COMMIT TRANSACTION"

proc generateInner(m: Markov, chatId: int, start: seq[string], limit: int
                  ): string {.tags:[ReadDbEffect,WriteIOEffect].} =
  var tokens = start
  var messageIds: seq[int] = @[]
  result = ""
  for n in 0..limit-1:
    let nextStep = m.db.selectNext(chatId, tokens, messageIds, result.len == 0)
    nextStep ?-> (next, messageId, initialWords):
      if next == "$end":
        # Try to generate next token again to prevent too short result.
        # The closer we are to `limit` the less trying again is likely.
        if limit.sqr.rand > n.sqr:
          debug "  ..."
          continue
        else:
          break
      tokens.rankAdd next.strip.toLower
      messageIds.rankAdd messageId
      if result.len == 0:
        result = initialWords.filter(x => x!="$start").join
      result.add next
    else:
      break

proc generate*(m: Markov, chatId: int, start: string, limit: int
              ): string {.tags:[ReadDbEffect,WriteIOEffect].} =
  ## Generate text using first tokens of `start` as an prefix.
  ## If it is not possible, start from random first token.
  var tokens = map(toSeq(start.tokenize), s => s.toLower.strip)
  if tokens.len > rank:
    tokens = tokens[0..rank-1]
  debug "From: " & tokens.join(" ")
  result = generateInner(m, chatId, tokens, limit)
  if result.len == 0:
    debug "From $start"
    result = generateInner(m, chatId, @["$start"], limit)
  debug "Generated: " & result
  debug ""
