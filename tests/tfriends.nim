import hypixel, strutils, os, asyncdispatch, terminal

# Create a text file in this directory called "apikey.txt" and paste your Hypixel API key into it.
let apikey = readFile(getAppDir() / "apikey.txt").strip()

proc echoAll(f: FriendsList) =
  echo f.owner
  for i, friend in f.records:
    echo friend
    echo f.friend(friend)

block Synchronous:
  var api = newHypixelApi(apikey)
  var f = api.getFriendsList("c373bfbc97474bb3b0ebe03bd168944b")
  echoAll f

echo "Synchronous test finished; press any key to test asynchronously."
discard getch()
eraseScreen()

block Asynchronous:
  proc test() {.async.} =
    var api = newAsyncHypixelApi(apikey)
    var f = await api.getFriendsList("c373bfbc97474bb3b0ebe03bd168944b")
    echoAll f
  waitFor test()