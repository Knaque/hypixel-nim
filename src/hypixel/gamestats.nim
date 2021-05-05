import common

type
  GameStats = object of HypixelObject

  SkywarsStats* = object of GameStats
    star*, coins*, kills*, assists*, deaths*, wins*, losses*, heads*: int
    kdr*, wlr*: float

  DuelsStats* = object of GameStats
    coins*, kills*, deaths*, wins*, losses*: int
    kdr*, wlr*: float
  
  BedwarsStats* = object of GameStats
    coins*, winstreak*, star*, kills*, deaths*, finalKills*, finalDeaths*: int
    wins*, losses*, bedsBroken*: int
    kdr*, fkdr*, wlr*: float
  
proc level*(s: SkywarsStats): int = s.star
proc level*(s: BedwarsStats): int = s.star