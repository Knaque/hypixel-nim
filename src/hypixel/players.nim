import hypixelcommon, times, tables, json, asyncdispatch, httpclient, strformat, options, gamestats, strutils, leveling, getters, playercommon
export gamestats.level, playercommon.AchievementRewardsNew, playercommon.PlusColor, playercommon.MonthlyRankColor

type
  Rank* = enum ## An enum describing every rank on the server.
    Non, Vip, VipPlus, Mvp, MvpPlus, MvpPlusPlus, Helper, Mod, Admin, Owner, YouTube,
    Sloth, Events, Mcp, Pig

  LevelUp* = object of PlayerObject
    ## The times at which a player bought a rank upgrade. Returns `none(DateTime)` if they never bought that rank.
    vip*, vipPlus*, mvp*, mvpPlus*: Option[DateTime]
  
  SocialMedia* = object of PlayerObject
    ## Each social media account linked to this player.
    discord*, twitch*, twitter*, youtube*, instagram*, forums*: string

  Stats* = object of PlayerObject
    ## An object containing individual games.
    skywars*: SkywarsStats
    bedwars*: BedwarsStats
    duels*: DuelsStats

  Player* = object of PlayerObject
    ## An object representing a player.
    id*, uuid*, playerName*, displayName*, mcVersionRp*: string
    mostRecentGameType*: string
    firstLogin*, lastLogin*, lastLogout*: DateTime
    knownAliases*, knownAliasesLower*, achievementsOneTime*: seq[string]
    friendRequestsUuid*, achievementTracking*: seq[string]
    networkExp*, karma*, achievementPoints*: int
    levelUp*: LevelUp
    achievementRewardsNew*: AchievementRewardsNew
    achievements*: Table[string, int]
    socialMedia*: SocialMedia
    rank*: Rank
    rankPlusColor*: PlusColor
    monthlyRankColor*: MonthlyRankColor
    stats*: Stats
    level*: float

proc `[]`*(t: AchievementRewardsNew, k: int): DateTime =
  ## Force `k` to be a power of 100, since that's what's used in the API.
  try:
    doAssert k mod 100 == 0
  except:
    let e = getCurrentException()
    e.msg = "'k' must be a multiple of 100."
    raise e
  return t.t[k]



proc playerConstructor(j: JsonNode): Player =
  if j["success"].getBool != true:
    raise newException(HypixelApiError, "Hypixel API request failed. (Rate limited?)")
  
  let player = j["player"]

  let uuid = player{"uuid"}.getStr

  var levelUp: LevelUp
  try: levelUp.vip = some(player["levelUp_VIP"].getTime) # we actually want it to crash here, so use []
  except: levelUp.vip = none(DateTime)
  try: levelUp.vipPlus = some(player["levelUp_VIP_PLUS"].getTime)
  except: levelUp.vipPlus = none(DateTime)
  try: levelUp.mvp = some(player["levelUp_MVP"].getTime)
  except: levelUp.mvp = none(DateTime)
  try: levelUp.mvpPlus = some(player["levelUp_MVP_PLUS"].getTime)
  except:levelUp.mvpPlus = none(DateTime)

  let sm = player{"socialMedia"}{"links"}
  var socialMedia: SocialMedia
  socialMedia.discord = sm{"DISCORD"}.getStr
  socialMedia.twitch = sm{"TWITCH"}.getStr
  socialMedia.twitter = sm{"TWITTER"}.getStr
  socialMedia.youtube = sm{"YOUTUBE"}.getStr
  socialMedia.instagram = sm{"INSTAGRAM"}.getStr
  socialMedia.forums = sm{"HYPIXEL"}.getStr

  var rank = Non # rank heirarchy
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
  of "b876ec32e396476ba1158438d83c67d4": rank = Pig # api is dumb, use uuids for special ranks
  else: discard

  var stats: Stats
  let skywars = player{"stats"}{"SkyWars"}
  stats.skywars.star = player{"achievements"}{"skywars_you_re_a_star"}.getInt
  stats.skywars.heads = player{"achievements"}{"skywars_heads"}.getInt
  stats.skywars.coins = skywars{"coins"}.getInt
  stats.skywars.kills = skywars{"kills"}.getInt
  stats.skywars.assists = skywars{"assists"}.getInt
  stats.skywars.deaths = skywars{"deaths"}.getInt
  stats.skywars.wins = skywars{"wins"}.getInt
  stats.skywars.losses = skywars{"losses"}.getInt
  stats.skywars.kdr = stats.skywars.kills / stats.skywars.deaths.clamp(1, high(int)) # prevent divison by zero error
  stats.skywars.wlr = stats.skywars.wins / stats.skywars.losses.clamp(1, high(int))
  let bedwars = player{"stats"}{"Bedwars"}
  stats.bedwars.star = player{"achievements"}{"bedwars_level"}.getInt
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
  let duels = player{"stats"}{"Duels"}
  stats.duels.coins = duels{"coins"}.getInt
  stats.duels.kills = duels{"kills"}.getInt
  stats.duels.deaths = duels{"deaths"}.getInt
  stats.duels.wins = duels{"wins"}.getInt
  stats.duels.losses = duels{"losses"}.getInt
  stats.duels.kdr = stats.duels.kills / stats.duels.deaths.clamp(1, high(int))
  stats.duels.wlr = stats.duels.wins / stats.duels.losses.clamp(1, high(int))

  return Player(
    id: player{"_id"}.getStr, 
    uuid: uuid,
    playerName: player{"playername"}.getStr, 
    displayName: player{"displayname"}.getStr, 
    mcVersionRp: player{"mcVersionRp"}.getStr, 
    rankPlusColor: player{"rankPlusColor"}.getPlusColor,
    mostRecentGameType: player{"mostRecentGameType"}.getStr, 
    monthlyRankColor: player{"monthlyRankColor"}.getMonthlyRankColor,
    firstLogin: player{"firstLogin"}.getTime, 
    lastLogin: player{"lastLogin"}.getTime, 
    lastLogout: player{"lastLogout"}.getTime,
    knownAliases: player{"knownAliases"}.getSeq, 
    knownAliasesLower: player{"knownAliasesLower"}.getSeq, 
    achievementsOneTime: player{"achievementsOneTime"}.getSeq,
    friendRequestsUuid: player{"friendRequestsUuid"}.getSeq, 
    achievementTracking: player{"achievementTracking"}.getSeq, 
    networkExp: player{"networkExp"}.getInt, 
    karma: player{"karma"}.getInt, 
    achievementPoints: player{"achievementPoints"}.getInt,
    levelUp: levelUp,
    achievementRewardsNew: player{"achievementRewardsNew"}.getTimeTable,
    achievements: player{"achievements"}.getIntTable,
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