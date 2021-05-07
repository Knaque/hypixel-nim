import common, times, asyncdispatch, json, httpclient, strformat

type
  FriendObject = object of HypixelObject
  Friend* = object of FriendObject
    id*, sender*, receiver*: string
    started*: DateTime
  FriendsList* = object of FriendObject
    owner*: string
    records*: seq[Friend]

proc `[]`*(l: FriendsList, i: int): Friend =
  return l.records[i]

proc friend*(l: FriendsList, f: Friend): string =
  if f.sender == l.owner: return f.receiver
  return f.sender



proc friendsListConstructor(j: JsonNode): FriendsList =
  if j["success"].getBool != true:
    raise newException(HypixelApiError, "Hypixel API request failed. (Rate limited?)")

  result.owner = j["uuid"].getStr

  let records = j["records"]

  for r in records.getElems:
    result.records.add(
      Friend(
        id: r["_id"].getStr,
        sender: r["uuidSender"].getStr,
        receiver: r["uuidReceiver"].getStr,
        started: r["started"].getDateTime,
      )
    )



proc getFriendsList*(api: HypixelApi or AsyncHypixelApi, uuid: string): Future[FriendsList] {.multisync.} =
  var response = await api.client.get(
    &"https://api.hypixel.net/friends?key={api.key}&uuid={uuid}"
  )
  return friendsListConstructor(
    parseJson(
      await response.body
    )
  )