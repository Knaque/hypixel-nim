import common, times, tables, json, asyncdispatch, httpclient, strformat, options, gamestats, sequtils, strutils, leveling
export gamestats.level

type
  PlayerObject = object of HypixelObject ## The roof object for the Player API.

  Rank* = enum ## An enum describing every rank on the server.
    Non, Vip, VipPlus, Mvp, MvpPlus, MvpPlusPlus, Helper, Mod, Admin, Owner, YouTube,
    Sloth, Events, Mcp, Pig
  RankPlusColor* = enum ## An enum describing every color the + of a rank can be.
    Red, Gold, Green, Yellow, LightPurple, White, Blue, DarkGreen, DarkRed,
    DarkAqua, DarkPurple, DarkGray, Black, DarkBlue
  MonthlyRankColor* = enum ## An enum describing the two colors an MVP++ can be.
    mGold, mAqua

  LevelUp* = object of PlayerObject
    vip*, vipPlus*, mvp*, mvpPlus*: Option[DateTime]
  
  SocialMedia* = object of PlayerObject
    discord*, twitch*, twitter*, youtube*, instagram*, forums*: string
  
  AchievementRewardsNew* = object of PlayerObject
    t: Table[int, DateTime]

  Stats* = object of PlayerObject
    skywars*: SkywarsStats
    bedwars*: BedwarsStats
    duels*: DuelsStats

  Player* = object of PlayerObject
    id*, uuid*, playerName*, displayName*, mcVersionRp*: string
    mostRecentGameType*: string
    firstLogin*, lastLogin*, lastLogout*: DateTime
    lastClaimedReward*: Option[DateTime]
    knownAliases*, knownAliasesLower*, achievementsOneTime*: seq[string]
    friendRequestsUuid*, achievementTracking*: seq[string]
    networkExp*, karma*, achievementPoints*: int
    levelUp*: LevelUp
    achievementRewardsNew*: AchievementRewardsNew
    achievements*: Table[string, int]
    socialMedia*: SocialMedia
    rank*: Rank
    rankPlusColor*: RankPlusColor
    monthlyRankColor*: MonthlyRankColor
    stats*: Stats
    level*: float

proc `[]`*(t: AchievementRewardsNew, k: int): DateTime =
  try:
    doAssert k mod 100 == 0
  except:
    let e = getCurrentException()
    e.msg = "'k' must be a multiple of 100."
    raise e
  return t.t[k]



proc getSeq(j: JsonNode): seq[string] =
  j.getElems.map(
    proc(x: JsonNode): string = x.getStr
  )

proc getDTTable(j: JsonNode): AchievementRewardsNew =
  var t = initTable[int, DateTime]()
  try:
    for a, b in j["achievementRewardsNew"].pairs:
      t[a[11..^1].parseInt] = b.getDateTime
  except KeyError: discard
  result.t = t

proc getIntTable(j: JsonNode): Table[string, int] =
  for a, b in j.pairs: result[a] = b.getInt

proc getRankPlusColor(j: JsonNode): RankPlusColor =
  try:
    case j.getStr
    of "GOLD": return Gold 
    of "GREEN": return Green
    of "YELLOW": return Yellow
    of "LIGHT_PURPLE": return LightPurple
    of "WHITE": return White
    of "BLUE": return Blue
    of "DARK_GREEN": return DarkGreen
    of "DARK_RED": return DarkRed
    of "DARK_AQUA": return DarkAqua
    of "DARK_PURPLE": return DarkPurple
    of "DARK_GRAY": return DarkGray
    of "BLACK": return Black
    of "DARK_BLUE": return DarkBlue
    else: return Red
  except KeyError: return Gold

proc getMonthlyRankColor(j: JsonNode): MonthlyRankColor =
  if j.getStr == "AQUA": return mAqua
  return mGold

proc playerConstructor(j: JsonNode): Player =
  if j["success"].getBool != true:
    raise newException(HypixelApiError, "Hypixel API request failed. (Rate limited?)")
  
  let player = j["player"]

  let uuid = player["uuid"].getStr

  var levelUp: LevelUp
  try: levelUp.vip = some(player["levelUp_VIP"].getDateTime)
  except: levelUp.vip = none(DateTime)
  try: levelUp.vipPlus = some(player["levelUp_VIP_PLUS"].getDateTime)
  except: levelUp.vipPlus = none(DateTime)
  try: levelUp.mvp = some(player["levelUp_MVP"].getDateTime)
  except: levelUp.mvp = none(DateTime)
  try: levelUp.mvpPlus = some(player["levelUp_MVP_PLUS"].getDateTime)
  except:levelUp.mvpPlus = none(DateTime)

  let sm = player{"socialMedia"}{"links"}
  var socialMedia: SocialMedia
  socialMedia.discord = sm{"DISCORD"}.getStr
  socialMedia.twitch = sm{"TWITCH"}.getStr
  socialMedia.twitter = sm{"TWITTER"}.getStr
  socialMedia.youtube = sm{"YOUTUBE"}.getStr
  socialMedia.instagram = sm{"INSTAGRAM"}.getStr
  socialMedia.forums = sm{"HYPIXEL"}.getStr

  var rank = Non
  if isSome(levelUp.vip): rank = Vip
  if isSome(levelUp.vipPlus): rank = VipPlus
  if isSome(levelUp.mvp): rank = Mvp
  if isSome(levelUp.mvpPlus): rank = MvpPlus
  if player{"monthlyPackageRank"}.getStr == "SUPERSTAR": rank = MvpPlusPlus
  if player{"rank"}.getStr == "YOUTUBER": rank = YouTube
  if player{"rank"}.getStr == "HELPER": rank = Helper
  if player{"rank"}.getStr == "MODERATOR": rank = Mod
  if player{"rank"}.getStr == "ADMIN": rank = Admin
  case uuid
  of "f7c77d999f154a66a87dc4a51ef30d19", "9b2a30ecf8b34dfebf499c5c367383f8": rank = Owner
  of "7dee85b445b348f0891850c1be2e0ca2": rank = Sloth
  of "c1ec7a0544d84dd8a44a6eb400570ed7": rank = Mcp
  of "b876ec32e396476ba1158438d83c67d4": rank = Pig
  else: discard

  var stats: Stats
  let skywars = player["stats"]["SkyWars"]
  stats.skywars.star = player["achievements"]{"skywars_you_re_a_star"}.getInt
  stats.skywars.heads = player["achievements"]{"skywars_heads"}.getInt
  stats.skywars.coins = skywars{"coins"}.getInt
  stats.skywars.kills = skywars{"kills"}.getInt
  stats.skywars.assists = skywars{"assists"}.getInt
  stats.skywars.deaths = skywars{"deaths"}.getInt
  stats.skywars.wins = skywars{"wins"}.getInt
  stats.skywars.losses = skywars{"losses"}.getInt
  stats.skywars.kdr = stats.skywars.kills / stats.skywars.deaths.clamp(1, high(int))
  stats.skywars.wlr = stats.skywars.wins / stats.skywars.losses.clamp(1, high(int))
  let bedwars = player["stats"]["Bedwars"]
  stats.bedwars.star = player["achievements"]{"bedwars_level"}.getInt
  stats.bedwars.coins = bedwars{"coins"}.getInt
  stats.bedwars.winstreak = bedwars{"winstreak"}.getInt
  stats.bedwars.kills = bedwars{"kills_bedwars"}.getInt
  stats.bedwars.deaths = bedwars{"deaths_bedwars"}.getInt
  stats.bedwars.finalKills = bedwars{"final_kills_bedwars"}.getInt
  stats.bedwars.finalDeaths = bedwars{"final_deaths_bedwars"}.getInt
  stats.bedwars.wins = bedwars{"wins_bedwars"}.getInt
  stats.bedwars.losses = bedwars{"losses_bedwars"}.getInt
  stats.bedwars.bedsBroken = bedwars{"beds_broken_bedwars"}.getInt
  stats.bedwars.kdr = stats.bedwars.kills / stats.bedwars.deaths.clamp(1, high(int))
  stats.bedwars.fkdr = stats.bedwars.finalKills / stats.bedwars.finalDeaths.clamp(1, high(int))
  stats.bedwars.wlr = stats.bedwars.wins / stats.bedwars.losses.clamp(1, high(int))
  let duels = player["stats"]["Duels"]
  stats.duels.coins = duels{"coins"}.getInt
  stats.duels.kills = duels{"kills"}.getInt
  stats.duels.deaths = duels{"deaths"}.getInt
  stats.duels.wins = duels{"wins"}.getInt
  stats.duels.losses = duels{"losses"}.getInt
  stats.duels.kdr = stats.duels.kills / stats.duels.deaths.clamp(1, high(int))
  stats.duels.wlr = stats.duels.wins / stats.duels.losses.clamp(1, high(int))

  var monthlyRankColor: MonthlyRankColor
  try: monthlyRankColor = player["monthlyRankColor"].getMonthlyRankColor
  except KeyError: monthlyRankColor = mGold

  return Player(
    id: player["_id"].getStr, 
    uuid: uuid, 
    playerName: player["playername"].getStr, 
    displayName: player["displayname"].getStr, 
    mcVersionRp: player{"mcVersionRp"}.getStr, 
    rankPlusColor: player.getRankPlusColor, 
    mostRecentGameType: player{"mostRecentGameType"}.getStr, 
    monthlyRankColor: monthlyRankColor,
    firstLogin: player["firstLogin"].getDateTime, 
    lastLogin: player["lastLogin"].getDateTime, 
    lastLogout: player["lastLogout"].getDateTime,
    knownAliases: player["knownAliases"].getSeq, 
    knownAliasesLower: player["knownAliasesLower"].getSeq, 
    achievementsOneTime: player["achievementsOneTime"].getSeq,
    friendRequestsUuid: player["friendRequestsUuid"].getSeq, 
    achievementTracking: player["achievementTracking"].getSeq, 
    networkExp: player["networkExp"].getInt, 
    karma: player["karma"].getInt, 
    achievementPoints: player["achievementPoints"].getInt,
    levelUp: levelUp,
    achievementRewardsNew: player.getDTTable,
    achievements: player["achievements"].getIntTable,
    socialMedia: socialMedia,
    rank: rank,
    stats: stats,
    level: getNetworkLevel(player{"networkExp"}.getFloat, player{"networkLevel"}.getFloat)
  )

proc getPlayerFromUuid*(api: HypixelApi or AsyncHypixelApi, uuid: string): Future[Player] {.multisync.} =
  ## Get a Player object from a player's UUID.
  var response = await api.client.get(
    &"https://api.hypixel.net/player?key={api.key}&uuid={uuid}"
  )
  return playerConstructor(
    parseJson(
      await response.body
    )
  )

proc getPlayerFromName*(api: HypixelApi or AsyncHypixelApi, name: string): Future[Player] {.multisync.} =
  ## Get a Player object from a player's username. This makes two HTTP requests:
  ## One to Mojang, and the other to Hypixel.
  var uuid: string
  var mojangapi = await api.client.post(
    "https://api.mojang.com/profiles/minecraft", &"[\"{name}\"]"
  )
  uuid = parseJson(
    await mojangapi.body
  ).getElems[0]["id"].getStr

  var response = await api.client.get(
    &"https://api.hypixel.net/player?key={api.key}&uuid={uuid}"
  )
  return playerConstructor(
    parseJson(
      await response.body
    )
  )