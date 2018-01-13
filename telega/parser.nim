import ./types
import json
import options
import strutils
import tables
import typetraits

type TelegaParsingError* = object of ValueError

proc telegaNormalize(s: string, chomp: bool = false): string =
  ## Convert camelCase to snake_case.
  result = ""
  var ignore = chomp
  for c in s:
    if c in 'A'..'Z':
      if not ignore:
        result.add('_')
      result.add(c.toLowerAscii)
      ignore = false
    elif not ignore:
      result.add(c)
  if result == "kind":
    result = "type"
  if result == "from_user":
    result = "from"

proc assertKind(node: JsonNode, kind: JsonNodeKind) =
  if isNil(node) or node.kind != kind:
    raise newException(TelegaParsingError, "Node is not " & $kind)

proc get(node: JsonNode, name: string): JsonNode =
  if node.fields.hasKey name:
    node.fields[name]
  else:
    nil

proc unmarshal(node: JsonNode, T: typedesc): T =
  when T is enum | ref | seq | Option:
    parseNode(node, result)
  elif T is bool:   node.parsePrimitive(JBool,   getBVal, bool)
  elif T is int32:  node.parsePrimitive(JInt,    getNum,  int32)
  elif T is int64:  node.parsePrimitive(JInt,    getNum,  int64)
  elif T is uint:   node.parsePrimitive(JInt,    getNum,  uint)
  elif T is string: node.parsePrimitive(JString, getStr,  string)
  elif T is float:  0.float # FIXME
  else:
    for a, b in result.fieldPairs:
      b = unmarshal(node.get a.telegaNormalize, b.type)

template parsePrimitive(node: JsonNode, kind: JsonNodeKind,
                        getWhat: untyped, T: untyped): untyped =
  node.assertKind kind
  node.getWhat.T

proc parseNode[T](node: JsonNode, res: var seq[T]) =
  node.assertKind JArray
  let elems = node.getElems
  res = newSeq[T](elems.len)
  for i in 0..elems.len-1:
    res[i] = unmarshal(elems[i], T)

proc parseNode[T](node: JsonNode, res: var Option[T]) =
  if node.isNil:
    res = none(T)
  else:
    res = unmarshal(node, T).some

proc parseNode[T](node: JsonNode, res: var ref T) =
  if node.isNil:
    res = nil
  else:
    new(res)
    res[] = unmarshal(node, T)

proc parseNode[T: enum](node: JsonNode, res: var T) =
  node.assertKind JString
  let s = node.getStr()
  res = high(T)
  for i in low(T)..high(T).pred:
    if s == ($i).telegaNormalize(true):
      res = i
      break

proc parseUpdates*(node: JsonNode): seq[Update] =
  node.unmarshal seq[Update]

proc parseUser*(node: JsonNode): User =
  node.unmarshal User

proc parseMessage*(node: JsonNode): Message =
  node.unmarshal Message
