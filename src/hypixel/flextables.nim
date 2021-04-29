## Case-insensitive Tables. Also ignores underscores.

import tables, strutils

type Flextable*[T] = object
  ## The Flextable object; secretly just a container for a regular Table.
  table: Table[string, T]

proc initFlextable*[T](): Flextable[T] =
  ## Create a new, empty Flextable.
  Flextable[T](table: initTable[string, T]())

proc `[]=`*[T](t: var Flextable[T], key: string, val: sink T) =
  ## Assign `val` to `key` in a Flextable.
  t.table[key.toLowerAscii.replace("_", " ")] = val

proc `[]`*[T](t: Flextable[T], key: string): T =
  ## Returns the value corresponding to `key` from the Flextable.
  t.table[key.toLowerAscii.replace("_", " ")]