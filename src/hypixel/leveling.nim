## Contains the math and logic used to calculate levels for players and guilds.

import math

const
  BASE = 10000
  GROWTH = 2500
  HALF_GROWTH = GROWTH / 2
  REVERSE_PQ_PREFIX = -(BASE - 0.5 * GROWTH)/GROWTH
  REVERSE_CONST = REVERSE_PQ_PREFIX * REVERSE_PQ_PREFIX
  GROWTH_DIVIDES_2 = 2/GROWTH
  EXP_NEEDED = [100000, 150000, 250000, 500000, 750000, 1000000, 1250000, 1500000, 2000000, 2500000, 2500000, 2500000, 2500000, 2500000, 3000000]

func getTotalExpToFullLevel(level: float): float =
  return (HALF_GROWTH * (level-2) + BASE) * (level-1)

proc getTotalExpToLevel(level: float): float =
  let
    lv = floor(level)
    x0 = getTotalExpToFullLevel(lv)
  if level == lv:
    return x0
  else:
    return (getTotalExpToFullLevel(lv+1) - x0) * floorMod(level, 1) + x0

func getLevel(exp: float): float =
  floor(1+REVERSE_PQ_PREFIX + sqrt(REVERSE_CONST+GROWTH_DIVIDES_2 * exp))

proc getPercentageToNextLevel(exp: float): float =
  let
    lv = getLevel(exp)
    x0 = getTotalExpToLevel(lv)
  return (exp-x0) / (getTotalExpToLevel(lv+1) - x0)

func getExactLevel(exp: float): float =
  getLevel(exp) + getPercentageToNextLevel(exp)

proc getExperience(EXP_FIELD, LVL_FIELD: float): float =
  var exp = EXP_FIELD
  exp += getTotalExpToFullLevel(LVL_FIELD + 1)
  return exp

proc getNetworkLevel*(networkExp, networkLevel: float): float =
  let exp = getExperience(networkExp, networkLevel)
  result = getExactLevel(exp)

proc getGuildLevel*(e: int): int =
  var exp = e
  var level = 0
  for i in 0..1000:
    var need = 0
    if i >= EXP_NEEDED.len: need = EXP_NEEDED[^1]
    else: need = EXP_NEEDED[i]
    if exp - need < 0: return toInt(round((level.toFloat + (exp / need)) * 100) / 100)
    level += 1; exp -= need
  return 1000