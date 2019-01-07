# This file is a part of xzfc/useless-tg-bot.
# This is free and unencumbered software released into the public domain.

import strutils

const
  aboutHelp* = unindent"""
    Примеры команд:
    @$1 -- сплетница
    /about me
    /about @$1
    /about by @$1
    /about del @$1
    /about rating
  """
  aboutAdded*       = "Записала!"
  aboutDeleted*     = "Удалила!"
  aboutUpdated*     = "Переписала!"
  aboutEmptyRating* = "But nobody came."
  aboutNoAbout*     = "Ещё никто не говорил о $1."
  aboutNoAboutBy*   = "$1 ещё ни о ком не говорил."
  aboutUnknownUser* = "Не видела тут $1."
  aboutCantAdd*     = "Добавлять записи можно только в группе."
  aboutCantDelete*  = "Удалять записи можно только в группе."

  deleteNo*         = "не"

  identity*         = unindent"""
    <b>ID</b>: $1
    <b>Ссылка</b>: <a href="tg://user?id=$1">$2</a>
    <b>Имена</b>:
    $3
    <b>Юзернеймы</b>:
    $4
  """

  control* = unindent"""
    <code>/control forget-identity</code>
      — забыть имена и юзернеймы в /identity
  """
  controlForgetIdentityDone* = "Забыла $1 записей!"
