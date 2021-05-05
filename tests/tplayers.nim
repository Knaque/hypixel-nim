import hypixel, terminal, os, strutils, asyncdispatch

let apikey = readFile(getAppDir() / "apikey.txt").strip()

proc echoAll(p: Player) =
  echo p.id
  echo p.uuid
  echo p.displayName
  echo p.mcVersionRp
  echo p.mostRecentGameType
  echo p.firstLogin
  echo p.lastLogin
  echo p.lastLogout
  echo p.networkExp
  echo p.karma
  echo p.achievementPoints
  echo p.levelUp.mvpPlus
  echo p.achievementRewardsNew[200]
  echo p.achievements["bedwars_loot_box"]
  echo p.socialMedia.discord
  echo p.rank
  echo p.rankPlusColor
  echo p.monthlyRankColor
  echo p.stats.skywars.star
  echo p.stats.skywars.kdr
  echo p.stats.skywars.wlr
  echo p.stats.bedwars.level
  echo p.stats.bedwars.kdr
  echo p.stats.bedwars.wlr
  echo p.stats.duels.wins
  echo p.stats.duels.kills
  echo p.level
  stdout.write("\n\n\n")

block Synchronous:
  for username in ["pssm", "ChocoMelky", "MindBlown"]:
    var api = newHypixelApi(apikey)
    let player = api.getPlayerFromName(username)
    player.echoAll

echo "Synchronous test finished; press any key to test asynchronously."
discard getch()
eraseScreen()

block Async:
  proc test() {.async.} =
    for username in ["pssm", "ChocoMelky", "MindBlown"]:
      var api = newAsyncHypixelApi(apikey)
      let player = await api.getPlayerFromName(username)
      echoAll(player)
  waitFor test()