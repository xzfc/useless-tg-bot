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
    <b>Имена</b>:
    $2
    <b>Юзернеймы</b>:
    $3
  """
