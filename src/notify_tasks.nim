import std/os
import std/strutils
import std/sequtils
import std/tables
import std/times
import std/uri
import types
import markdown_analyzer
import scheduling
import logger
import std/logging

proc main() =
  # process and validate arguments ---------------------------------------------
  if paramCount() < 2:
    echo("notify-tasks requires two positional arguments: the root directory of your markdown vault, and the ntfy url.")
    quit(QuitFailure)
  elif paramCount() > 2:
    echo("Warning: notify-tasks only accepts two arguments. Ignoring everything after " & paramStr(2))
  
  # first argument is the root directory
  let root = paramStr(1)
  if dirExists(root) != true:
    echo(root & " is not a valid directory.")
    quit(QuitFailure)

  let input_url = paramStr(2)
  var parsedUrl = initUri()
  try:
    parsedUrl = parseUri(input_url)
  except UriParseError as e:
    nt_logger.log(lvlError, e.msg)
    quit(QuitFailure)
  if parsedUrl.scheme != "https" and parsedUrl.scheme != "http":
    nt_logger.log(lvlError, "Url " & input_url & " is not of type http or https.")
    quit(QuitFailure)

  let url = $parsedUrl

  # main functionality ---------------------------------------------------------
  var modifiedDates: ref Table[string, int64] = new(Table[string, int64])
  var todos: TodoTable = TodoTable()
  todos = makeTodoTable(root, modifiedDates, todos)

  var nextNotification = Notification()
  var hasTodos = todos.retrieveNextNotification(nextNotification)

  if not hasTodos:
    nt_logger.log(lvlError, "No todos found in notes at " & root)
    quit(QuitFailure)

  while true:
    # TODO: fix what happens if there are multiple notifications at the same time
    # AND if there are two notifications within 10 seconds of each other
    # (program might skip the second one if its too latent)
    if now() >= nextNotification.date:
      # send the next notification to the ntfy url
      notify(nextNotification.description, url)
      todos.retrieveNextNotification(nextNotification)

    for file in todos.files:
      # check if the files have changed using last modified date
      if modifiedDates.contains(file):
        if (modifiedDates[file] == getFileInfo(file).lastWriteTime.toUnix()):
          continue
        else:
          nt_logger.log(lvlInfo, "file change detected...")
      else:
        # new file whose modified dates have not yet been saved, remake the db
        nt_logger.log(lvlInfo, "new file found: " & file)

      # reset the notifications schedule
      todos = makeTodoTable(root, modifiedDates, todos)
      hasTodos = todos.retrieveNextNotification(nextNotification)
    
    if not hasTodos:
      # slow down operational speed if no todos in notes
      os.sleep(10000)
      continue

    # "refresh rate"
    os.sleep(500)
  
  quit(QuitSuccess)


main()
