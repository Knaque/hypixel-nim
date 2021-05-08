import common, times, json, sequtils, httpclient, strformat, asyncdispatch, options, math, strutils

const EXP_NEEDED = [100000, 150000, 250000, 500000, 750000, 1000000, 1250000, 1500000, 2000000, 2500000, 2500000, 2500000, 2500000, 2500000, 3000000]

type
  GuildObject = object of HypixelObject ## Root object for the Hypixel Guild API.

  ExpHistoryEntry* = object of GuildObject
    ## An object representing a single day in the Gexp History log.
    date*: DateTime
    exp*: int
  GuildMember* = object of GuildObject
    ## An object representing a member of a guild.
    name*: Option[string]
    joined*: DateTime
    rank*, uuid*: string
    questParticipation*: Option[int]
    expHistory*: array[7, ExpHistoryEntry]

  GuildRank* = object of GuildObject
    ## An object representing a rank in a guild.
    name*, tag*: string
    default*: bool
    created*: DateTime
    priority*: int
  
  GuildExpByGameType* = object of GuildObject
    ## An object containing how much Gexp the guild has earned per gamemode.
    bedwars*, speedUhc* , tntGames*, buildBattle*, uhc*, legacy*, arena*: int
    housing*, walls*, skywars*, pit*, paintball*, battleground*: int
    quakecraft*, mcgo*, duels*, murderMystery*, vampirez*, arcade*: int
    superSmash*, walls3, skyblock*, prototype*, survivalGames*: int
    gingerbread*, replay*: int

  Achievements* = object of GuildObject
    ## An object containing the three achievements: `winners`, `experienceKings`, and `onlinePLayers`.
    winners*, experienceKings*, onlinePlayers*: int

  BannerBase = object of GuildObject ## Root object for banners.
  BannerPattern* = object of BannerBase
    ## An object representing a single banner pattern.
    pattern*, color*: string
  Banner* = object of BannerBase
    ## An object representing an entire banner.
    base*: int
    patterns*: seq[BannerPattern]

  Guild* = object of GuildObject
    ## An object representing a Guild.
    id*, name*, tagColor*, description*, nameLower*, tag*: string
    coins*, coinsEver*, exp*, legacyRanking*, chatMute*: int
    created*: DateTime
    joinable*, publiclyListed*: bool
    members*: seq[GuildMember]
    banner*: Banner
    achievements*: Achievements
    ranks*: seq[GuildRank]
    preferredGames*: seq[string]
    guildExpByGameType*: GuildExpByGameType
    level*: int

proc gexp*(g: Guild): int =
  ## Calling it 'gexp' might be more intuitive to some; this is the same as `g.exp`
  g.exp

proc guildConstructor(j: JsonNode): Guild =
  ## Turns the JSON into a Guild object with GuildMember and GuildRank children.
  if j["success"].getBool != true:
    raise newException(HypixelApiError, "Hypixel API request failed. (Rate limited?)")

  let guild = j["guild"]

  # Construct and collect each GuildMember object.
  var members: seq[GuildMember]
  for m in guild["members"].getElems:
    var name: Option[string]
    try: name = some(m["name"].getStr)
    except: name = none(string)

    var questParticipation: Option[int]
    try: questParticipation = some(m["questParticipation"].getInt)
    except: questParticipation = none(int)

    var expHistory: array[7, ExpHistoryEntry]
    var c = 0
    for d, e in m["expHistory"].pairs:
      expHistory[c].date = d.parse("yyyy-MM-dd", utc())
      expHistory[c].exp = e.getInt
      c += 1

    members.add(
      GuildMember(
        name: name,
        joined: m["joined"].getDateTime,
        rank: m["rank"].getStr,
        uuid: m["uuid"].getStr,
        questParticipation: questParticipation,
        expHistory: expHistory
      )
    )

  # Construct the banner field.
  var banner: Banner
  banner.base = guild["banner"]["Base"].getInt
  for p in guild["banner"]["Patterns"].getElems:
    var pattern: BannerPattern
    pattern.pattern = p["Pattern"].getStr
    pattern.color = p["Color"].getStr
    banner.patterns.add(pattern)

  # Construct and collect each GuildRank object.
  var ranks: seq[GuildRank]
  for r in guild["ranks"].getElems:
    ranks.add GuildRank(
      name: r["name"].getStr,
      default: r["default"].getBool,
      tag: r["tag"].getStr,
      created: r["created"].getDateTime,
      priority: r["priority"].getInt
    )
  
  # Construct the guildExpByGameType field.
  let gebgt = guild["guildExpByGameType"]
  var guildExpByGameType = GuildExpByGameType(
    bedwars: gebgt["BEDWARS"].getInt, speedUhc: gebgt["SPEED_UHC"].getInt,
    tntGames: gebgt["TNTGAMES"].getInt,
    buildBattle: gebgt["BUILD_BATTLE"].getInt, uhc: gebgt["UHC"].getInt,
    legacy: gebgt["LEGACY"].getInt, arena: gebgt["ARENA"].getInt,
    housing: gebgt["HOUSING"].getInt, walls: gebgt["WALLS"].getInt,
    skywars: gebgt["SKYWARS"].getInt, pit: gebgt["PIT"].getInt,
    paintball: gebgt["PAINTBALL"].getInt,
    battleground: gebgt["BATTLEGROUND"].getInt,
    quakecraft: gebgt["QUAKECRAFT"].getInt, mcgo: gebgt["MCGO"].getInt,
    duels: gebgt["DUELS"].getInt, murderMystery: gebgt["MURDER_MYSTERY"].getInt,
    vampirez: gebgt["VAMPIREZ"].getInt, arcade: gebgt["ARCADE"].getInt,
    superSmash: gebgt["SUPER_SMASH"].getInt, walls3: gebgt["WALLS3"].getInt,
    skyblock: gebgt["SKYBLOCK"].getInt, prototype: gebgt["PROTOTYPE"].getInt,
    survivalGames: gebgt["SURVIVAL_GAMES"].getInt,
    gingerbread: gebgt["GINGERBREAD"].getInt, replay: gebgt["REPLAY"].getInt
  )

  # Calculate the guild's level from its exp
  let exp = guild["exp"].getInt
  proc calcLevel(e: int): int =
    var exp = e
    var level = 0
    for i in 0..1000:
      var need = 0
      if i >= EXP_NEEDED.len: need = EXP_NEEDED[^1]
      else: need = EXP_NEEDED[i]
      if exp - need < 0: return toInt(round((level.toFloat + (exp / need)) * 100) / 100)
      level += 1; exp -= need
    return 1000

  # Construct the final Guild object and return it.
  return Guild(
    id: guild["_id"].getStr,
    coins: guild["coins"].getInt,
    coinsEver: guild["coinsEver"].getInt,
    created: guild["created"].getDateTime,
    joinable: guild{"joinable"}.getBool,
    members: members,
    name: guild["name"].getStr,
    publiclyListed: guild["publiclyListed"].getBool,
    banner: banner,
    tagColor: guild["tagColor"].getStr,
    achievements: Achievements(
      winners: guild["achievements"]["WINNERS"].getInt,
      experienceKings: guild["achievements"]["EXPERIENCE_KINGS"].getInt,
      onlinePlayers: guild["achievements"]["ONLINE_PLAYERS"].getInt
    ),
    exp: exp,
    legacyRanking: guild["legacyRanking"].getInt + 1,
    ranks: ranks,
    chatMute: guild["chatMute"].getInt,
    preferredGames: toSeq(guild["preferredGames"].getElems).map(
      proc(x: JsonNode): string = x.getStr
    ),
    description: guild["description"].getStr,
    nameLower: guild["name_lower"].getStr,
    tag: guild["tag"].getStr,
    guildExpByGameType: guildExpByGameType,
    level: calcLevel(exp)
  )



proc getGuildFromId*(api: HypixelApi or AsyncHypixelApi, id: string): Future[Guild] {.multisync.} =
  ## Get a Guild object from a guild's ID.
  var response = await api.client.get(
    &"https://api.hypixel.net/guild?key={api.key}&id={id}"
  )
  return guildConstructor(
    parseJson(
      await response.body
    )
  )

proc getGuildFromPlayer*(api: HypixelApi or AsyncHypixelApi, uuid: string): Future[Guild] {.multisync.} =
  ## Get a Guild object from a member's UUID.
  var response = await api.client.get(
    &"https://api.hypixel.net/guild?key={api.key}&player={uuid}"
  )
  return guildConstructor(
    parseJson(
      await response.body
    )
  )

proc getGuildFromName*(api: HypixelApi or AsyncHypixelApi, name: string): Future[Guild] {.multisync.} =
  ## Get a Guild object from the guild's name.
  var response = await api.client.get(
    &"https://api.hypixel.net/guild?key={api.key}&name=" & name.replace(" ", "%20")
  )
  return guildConstructor(
    parseJson(
      await response.body
    )
  )