import macros
import options
import typetraits

template optionType*[T](a: Option[T]): auto =
  ## Leaked implementation detail. Do not use.
  T

template `?.`*[T](EXPR: Option[T], FIELD: untyped): auto =
  ## ``foo?.bar`` is either ``foo.get.bar`` or ``none`` depends of
  ## ``foo.isNone``.
  ## Can be chained, e.g. ``foo?.bar?.baz?.qux``
  let v = EXPR
  if v.isNone:
    none(v.get.FIELD.optionType)
  else:
    v.get.FIELD

template `?:`*[T](val: Option[T], default: T): T =
  ## Elvis operator.
  val.get(default)

proc valueExists*[T](x: Option[T]): bool =
  ## Used by ``?->`` macro.
  x.isSome
proc valueExists*[T](x: ref T): bool =
  ## Used by ``?->`` macro.
  x != nil

proc getValue*[T](x: Option[T]): T =
  ## Used by ``?->`` macro.
  x.get
proc getValue*[T](x: ref T): T =
  ## Used by ``?->`` macro.
  x[]

proc newLetStmt2(lhs, value: NimNode): NimNode {.compiletime.} =
  # Create a new let stmt
  var inner: NimNode
  if lhs.kind == nnkIdent:
    inner = newNimNode(nnkIdentDefs).add(lhs)
  else:
    inner = newNimNode(nnkVarTuple)
    copyChildrenTo(lhs, inner)
  inner.add(newNimNode(nnkEmpty), value)
  return newNimNode(nnkLetSection).add(inner)

proc optionMatch(EXPR, IDENT, BODY, ELSE_BODY: NimNode): NimNode =
  let v = genSym()
  let ifStmt = newIfStmt(
      (newDotExpr(v, newIdentNode "valueExists"),
       newStmtList(newLetStmt2(IDENT, newDotExpr(v, newIdentNode "getValue")),
                   BODY)))
  if not ELSE_BODY.isNil:
    ifStmt.add ELSE_BODY
  return newStmtList(newLetStmt(v, EXPR), ifStmt)

macro `?->`*(EXPR, IDENT, BODY, ELSE_BODY: untyped): untyped =
  ## Following code:
  ##
  ## .. code-block:: Nim
  ##   EXPR ?-> IDENT:
  ##     BODY
  ##   else:
  ##     ELSE_BODY
  ##
  ## Expands to:
  ##
  ## .. code-block:: Nim
  ##   let :v = EXPR
  ##   if :v.valueExists:
  ##     let IDENT = v.getValue
  ##     BODY
  ##   else:
  ##     ELSE_BODY
  ##
  ## Where ``EXPR`` have type ``Option[T]|ref T`` and ``IDENT`` have type ``T``.

  assert IDENT.kind == nnkIdent or IDENT.kind == nnkPar
  assert BODY.kind == nnkStmtList
  assert ELSE_BODY.kind == nnkElse
  return optionMatch(EXPR, IDENT, BODY, ELSE_BODY)

macro `?->`*(EXPR, IDENT, BODY: untyped): untyped =
  ## Following code:
  ##
  ## .. code-block:: Nim
  ##   EXPR ?-> IDENT:
  ##     BODY
  ##
  ## Expands to:
  ##
  ## .. code-block:: Nim
  ##   let :v = EXPR
  ##   if :v.valueExists:
  ##     let IDENT = v.getValue
  ##     BODY
  ##
  ## Where ``EXPR`` have type ``Option[T]|ref T`` and ``IDENT`` have type ``T``.

  assert IDENT.kind == nnkIdent or IDENT.kind == nnkPar
  assert BODY.kind == nnkStmtList
  return optionMatch(EXPR, IDENT, BODY, nil)

template getOrBreak*[T](EXPR: Option[T]): auto =
  let v = EXPR
  if v.isNone:
    break
  v.get

template getOrBreak*[T](EXPR: ref T): auto =
  let v = EXPR
  if v == nil:
    break
  v[]

template `.?`*[T](EXPR: Option[T] | ref T, FIELD: untyped): auto =
  EXPR.getOrBreak.FIELD

proc `//`*[T](a, b: Option[T]): Option[T] =
  if a.isSome:
    a
  else:
    b

proc toOption*[T](v: ref T): Option[T] =
  if v.isNil:
    T.none
  else:
    v[].some
