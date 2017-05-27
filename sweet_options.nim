import macros
import options
import typetraits

template optionType*[T](a : Option[T]) : auto =
  # Leaked implementation detail. Do not use.
  T

template `?.`*[T](EXPR: Option[T], FIELD: untyped): auto =
  # `foo?.bar` is either `foo.get.bar` or `none` depends of `foo.isNone`.
  # Can be chained, e.g. `foo?.bar?.baz?.qux`
  let v = EXPR
  if v.isNone:
    none(v.get.FIELD.optionType)
  else:
    v.get.FIELD

template `?:`*[T](val: Option[T], default: T): T =
  # Elvis operator.
  val.get(default)

proc optionMatch(EXPR, IDENT, BODY, ELSE_BODY: NimNode): NimNode =
  let v = genSym()
  let ifStmt = newIfStmt(
      (newDotExpr(v, newIdentNode "isSome"),
       newStmtList(newLetStmt(IDENT, newDotExpr(v, newIdentNode "get")),
                   BODY)))
  if not ELSE_BODY.isNil:
    ifStmt.add ELSE_BODY
  return newStmtList(newLetStmt(v, EXPR), ifStmt)

macro `?->`*(EXPR, IDENT, BODY, ELSE_BODY: untyped): untyped =
  # Following code:
  #
  #   EXPR ?-> IDENT:
  #     BODY
  #
  # Expands to:
  #
  #   let :v = EXPR
  #   if :v.isSome:
  #     let IDENT = v.get
  #     BODY
  #
  # Where EXPR have type Option[T] and IDENT have type T.

  assert IDENT.kind == nnkIdent
  assert BODY.kind == nnkStmtList
  assert ELSE_BODY.kind == nnkElse
  return optionMatch(EXPR, IDENT, BODY, ELSE_BODY)

macro `?->`*(EXPR, IDENT, BODY: untyped): untyped =
  # Following code:
  #
  #   EXPR ?-> IDENT:
  #     BODY
  #   else:
  #     ELSE_BODY
  #
  # Expands to:
  #
  #   let :v = EXPR
  #   if :v.isSome:
  #     let IDENT = v.get
  #     BODY
  #   else:
  #     ELSE_BODY
  #
  # Where EXPR have type Option[T] and IDENT have type T.

  assert IDENT.kind == nnkIdent
  assert BODY.kind == nnkStmtList
  return optionMatch(EXPR, IDENT, BODY, nil)
