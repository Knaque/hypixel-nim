import json, sequtils, times, strutils, tables, playercommon, options, unicode

const valid_digits = ["0".runeAt(0), "1".runeAt(0), "2".runeAt(0), "3".runeAt(0), "4".runeAt(0), "5".runeAt(0), "6".runeAt(0), "7".runeAt(0), "8".runeAt(0), "9".runeAt(0)]

proc getSeq*(j: JsonNode): seq[string] =
  if j == nil: return newSeq[string]()
  j.getElems.map(
    proc(x: JsonNode): string = x.getStr
  )

proc getTime*(time: JsonNode): DateTime =
  inZone(fromUnixFloat(time.getInt / 1000), utc())

proc getTimeTable*(j: JsonNode): AchievementRewardsNew =
  var t = initTable[int, DateTime]()
  if j != nil:
    for a, b in j.pairs:
      t[a[11..^1].parseInt] = b.getTime
  result.t = t

proc getIntTable*(j: JsonNode): Table[string, int] =
  if j == nil: return initTable[string, int]()
  for a, b in j.pairs: result[a] = b.getInt

proc getOptionalTime*(j: JsonNode, f: string): Option[DateTime] =
  try: return some(j[f].getTime)
  except KeyError: return none(DateTime)

proc getPlusColor*(j: JsonNode): PlusColor =
  case j.getStr
  of "GOLD": return GoldPlus
  of "GREEN": return GreenPlus
  of "YELLOW": return YellowPlus
  of "LIGHT_PURPLE": return LightPurplePlus
  of "WHITE": return WhitePlus
  of "BLUE": return BluePlus
  of "DARK_GREEN": return DarkGreenPlus
  of "DARK_RED": return DarkRedPlus
  of "DARK_AQUA": return DarkAquaPlus
  of "DARK_PURPLE": return DarkPurplePlus
  of "DARK_GRAY": return DarkGrayPlus
  of "BLACK": return BlackPlus
  of "DARK_BLUE": return DarkBluePlus
  else: return RedPlus

proc getMonthlyRankColor*(j: JsonNode): MonthlyRankColor =
  if j.getStr == "AQUA": return AquaMonthly
  return GoldMonthly

proc getSkywarsStar*(a, b: JsonNode): int =
  if a == nil:
    if b == nil: return 0
    let r = b.getStr.toRunes
    var b: seq[Rune]
    for i, c in r[1..^1]:
      if c in valid_digits and r[i] != "§".runeAt(0):
        b.add c
    return parseInt $b
  return a.getInt