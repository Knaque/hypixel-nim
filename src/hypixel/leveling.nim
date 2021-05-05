from math import floor, sqrt, floorMod

const
  BASE = 10000
  GROWTH = 2500
  HALF_GROWTH = GROWTH / 2
  REVERSE_PQ_PREFIX = -(BASE - 0.5 * GROWTH)/GROWTH
  REVERSE_CONST = REVERSE_PQ_PREFIX * REVERSE_PQ_PREFIX
  GROWTH_DIVIDES_2 = 2/GROWTH

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