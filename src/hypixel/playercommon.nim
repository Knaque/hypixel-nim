import tables, hypixelcommon, times

type
  PlayerObject* = object of HypixelObject ## The root object for the Player API.
  AchievementRewardsNew* = object of PlayerObject ## A table representing the "achievementRewardsNew" API field.
    t*: Table[int, DateTime]
  PlusColor* = enum ## An enum describing every color the + of a rank can be.
    RedPlus, GoldPlus, GreenPlus, YellowPlus, LightPurplePlus, WhitePlus,
    BluePlus, DarkGreenPlus, DarkRedPlus, DarkAquaPlus, DarkPurplePlus,
    DarkGrayPlus, BlackPlus, DarkBluePlus
  MonthlyRankColor* = enum ## An enum describing the two colors an MVP++ can be.
    GoldMonthly, AquaMonthly