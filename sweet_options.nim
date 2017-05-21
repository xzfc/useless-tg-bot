import macros
import options

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

macro `?->`*(EXPR, IDENT, BODY: untyped): untyped =
  # Pattern matching for Option[T] type.
  #
  # Following code:
  #
  #   EXPR ?-> IDENT:
  #     BODY
  #   else:        # optional
  #     ELSE_BODY  #
  #
  # Expands to:
  #
  #   let :v = EXPR
  #   if :v.isSome:
  #     let IDENT = v.get
  #   else:
  #     ELSE_BODY
  #
  # Where EXPR have type Option[T] and IDENT have type T.

  assert IDENT.kind == nnkIdent
  assert BODY.kind == nnkStmtList

  var ELSE_BODY : NimNode
  if BODY.last.kind == nnkElse:
    ELSE_BODY = BODY.last
    BODY.del(BODY.len - 1)

  let v = genSym()

  let ifStmt = newIfStmt(
      (newDotExpr(v, newIdentNode "isSome"),
       newStmtList(newLetStmt(IDENT, newDotExpr(v, newIdentNode "get")),
                   BODY)))
  if not ELSE_BODY.isNil:
    ifStmt.add ELSE_BODY
  return newStmtList(newLetStmt(v, EXPR), ifStmt)
