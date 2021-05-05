import hypixel, strutils, os, asyncdispatch, terminal

# Create a text file in this directory called "apikey.txt" and paste your Hypixel API key into it.
let apikey = readFile(getAppDir() / "apikey.txt").strip()

proc echoAll(g: Guild) =
  echo g.name
  echo g.tag
  echo g.created
  echo g.members.len
  echo g.level
  echo g.description
  echo g.publiclyListed
  echo g.joinable
  echo g.legacyRanking
  echo g.achievements.winners
  echo g.achievements.experienceKings
  echo g.achievements.onlinePlayers
  echo g.preferredGames
  for m in g.members:
    echo (m.uuid, m.joined, m.rank, m.expHistory, m.questParticipation, m.name)

block Synchronous:
  var api = newHypixelApi(apikey)
  var g = api.getGuildFromName("Matrix")
  echoAll(g)

echo "Synchronous test finished; press any key to test asynchronously."
discard getch()
eraseScreen()

block Asynchronous:
  proc test() {.async.} =
    var api = newAsyncHypixelApi(apikey)
    var g = await api.getGuildFromName("Matrix")
    echoAll(g)
  waitFor test()