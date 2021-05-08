import hypixelcommon

type
  GameStats = object of HypixelObject ## Root object for Hypixel game information.

  SkywarsStats* = object of GameStats
    ## Object containing Skywars stats.
    star*, coins*, kills*, assists*, deaths*, wins*, losses*, heads*: int
    kdr*, wlr*: float

  DuelsStats* = object of GameStats
    ## Object containing Duels stats.
    coins*, kills*, deaths*, wins*, losses*: int
    kdr*, wlr*: float
  
  BedwarsStats* = object of GameStats
    ## Object containing Bedwars stats.
    coins*, winstreak*, star*, kills*, deaths*, finalKills*, finalDeaths*: int
    wins*, losses*, bedsBroken*: int
    kdr*, fkdr*, wlr*: float
  
proc level*(s: SkywarsStats): int =
  ## Some people call it "level"; this is the same as `player.skywars.star`
  s.star
proc level*(s: BedwarsStats): int =
  ## Some people call it "level"; this is the same as `player.bedwars.star`
  s.star