import hycommon, times, flextables, json, sequtils, httpclient, strformat, asyncdispatch, options, math
export flextables.`[]`

const EXP_NEEDED = [100000, 150000, 250000, 500000, 750000, 1000000, 1250000, 1500000, 2000000, 2500000, 2500000, 2500000, 2500000, 2500000, 3000000]

type
  GuildObject = object of HypixelObject ## Root object for the Hypixel Guild API.
  GuildMember* = object of GuildObject
    ## An object representing a member of a guild.
    name*: Option[string]
    joined*: DateTime
    rank*, uuid*: string
    questParticipation*: Option[int]
    expHistory*: array[7, int]

  GuildRank* = object of GuildObject
    ## An object representing a rank in a guild.
    name*, tag*: string
    default*: bool
    created*: DateTime
    priority*: int

  Guild* = object of GuildObject
    ## An object representing a Guild.
    id*: string
    coins*, coinsEver*: int
    created*: DateTime
    joinable*: bool
    members*: seq[GuildMember]
    name*: string
    publiclyListed*: bool
    banner*: tuple[base: int, patterns: seq[tuple[pattern, color: string]]]
    tagColor*: string
    achievements*: Flextable[int]
    exp*, legacyRanking*: int
    ranks*: seq[GuildRank]
    chatMute*: int
    preferredGames*: seq[string]
    description*, nameLower*, tag*: string
    guildExpByGameType*: Flextable[int]

proc level*(g: Guild): int =
  ## Calculate the guild's level from its exp.
  var exp = g.exp
  var level = 0
  for i in 0..1000:
    var need = 0
    if i >= EXP_NEEDED.len: need = EXP_NEEDED[^1]
    else: need = EXP_NEEDED[i]
    if exp - need < 0: return toInt(round((level.toFloat + (exp / need)) * 100) / 100)
    level += 1; exp -= need
  return 1000

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

    var expHistory: array[7, int]
    var c = 0
    for _, x in m["expHistory"].pairs:
      expHistory[c] = x.getInt
      c += 1

    members.add(
      GuildMember(
        name: name,
        joined: fromUnixMs(m["joined"].getInt),
        rank: m["rank"].getStr,
        uuid: m["uuid"].getStr,
        questParticipation: questParticipation,
        expHistory: expHistory
      )
    )

  # Construct the banner field.
  var banner: tuple[base: int, patterns: seq[tuple[pattern, color: string]]]
  banner.base = guild["banner"]["Base"].getInt
  for p in guild["banner"]["Patterns"].getElems:
    var pattern: tuple[pattern, color: string]
    pattern.pattern = p["Pattern"].getStr
    pattern.color = p["Color"].getStr

  # Construct the achievements field.
  var achievements: Flextable[int]
  for a, v in guild["achievements"].pairs:
    achievements[a] = v.getInt

  # Construct and collect each GuildRank object.
  var ranks: seq[GuildRank]
  for r in guild["ranks"].getElems:
    ranks.add GuildRank(
      name: r["name"].getStr,
      default: r["default"].getBool,
      tag: r["tag"].getStr,
      created: fromUnixMs(r["created"].getInt),
      priority: r["priority"].getInt
    )

  # Construct the preferredGames field.
  var preferredGames = toSeq(guild["preferredGames"].getElems).map(
    proc(x: JsonNode): string = x.getStr
  )
  
  # Construct the guildExpByGameType field.
  var guildExpByGameType: Flextable[int]
  for g, x in guild["guildExpByGameType"].pairs:
    guildExpByGameType[g] = x.getInt

  # Construct the final Guild object and return it.
  return Guild(
    id: guild["_id"].getStr,
    coins: guild["coins"].getInt,
    coinsEver: guild["coinsEver"].getInt,
    created: fromUnixMs(guild["created"].getInt),
    joinable: guild["joinable"].getBool,
    members: members,
    name: guild["name"].getStr,
    publiclyListed: guild["publiclyListed"].getBool,
    banner: banner,
    tagColor: guild["tagColor"].getStr,
    achievements: achievements,
    exp: guild["exp"].getInt,
    legacyRanking: guild["legacyRanking"].getInt + 1,
    ranks: ranks,
    chatMute: guild["chatMute"].getInt,
    preferredGames: preferredGames,
    description: guild["description"].getStr,
    nameLower: guild["name_lower"].getStr,
    tag: guild["tag"].getStr,
    guildExpByGameType: guildExpByGameType
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
    &"https://api.hypixel.net/guild?key={api.key}&name={name}"
  )
  return guildConstructor(
    parseJson(
      await response.body
    )
  )