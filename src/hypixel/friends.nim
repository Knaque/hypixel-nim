import hypixelcommon, times, asyncdispatch, json, httpclient, strformat, getters

type
  FriendObject = object of HypixelObject ## Root object for the Friends API.
  Friend* = object of FriendObject ## An object describing a single friend.
    id*, sender*, receiver*: string
    started*: DateTime
  FriendsList* = object of FriendObject ## The entire friends list.
    owner*: string
    records*: seq[Friend]

proc len*(l: FriendsList): int =
  ## Shorthand for `l.records.len`
  return l.records.len

proc `[]`*(l: FriendsList, i: int): Friend =
  ## Shorthand for `l.records[0]`
  return l.records[i]

proc `[]`*(l: FriendsList, i: BackwardsIndex): Friend =
  ## Shorthand for `l.records[^1]`
  return l[l.len - i.int]

proc `[]`*(l: FriendsList, s: HSlice[int, int or BackwardsIndex]): seq[Friend] =
  ## Shorthand for `l.records[1..10]` and `l.records[1..^10]`
  return l.records[s]

iterator items*(l: FriendsList): Friend =
  ## Shorthand for `for f in friendsList.records`
  for f in l.records: yield f

iterator pairs*(l: FriendsList): tuple[index: int, value: Friend] =
  ## Shorthand for `for i, f in friendsList.records`
  for i, f in l.records: yield (i, f)

proc friend*(l: FriendsList, f: Friend): string =
  ## Between the sender and receiver, returns whoever isn't the owner of the list.
  if f.sender == l.owner: return f.receiver
  return f.sender



proc friendsListConstructor(j: JsonNode): FriendsList =
  if j["success"].getBool != true:
    raise newException(HypixelApiError, "Hypixel API request failed. (Rate limited?)")

  result.owner = j["uuid"].getStr

  let records = j{"records"}

  if records != nil:
    for r in records.getElems:
      result.records.add(
        Friend(
          id: r{"_id"}.getStr,
          sender: r{"uuidSender"}.getStr,
          receiver: r{"uuidReceiver"}.getStr,
          started: r{"started"}.getTime,
        )
      )



proc getFriendsList*(api: HypixelApi or AsyncHypixelApi, uuid: string): Future[FriendsList] {.multisync.} =
  ## Get a FriendsList from a player's UUID.
  var response = await api.client.get(
    &"https://api.hypixel.net/friends?key={api.key}&uuid={uuid}"
  )
  return friendsListConstructor(
    parseJson(
      await response.body
    )
  )