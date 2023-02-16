from std/os import dirExists, getFileInfo, sleep, paramCount, paramStr
from std/tables import Table, contains
import std/tables # for table[key] lookup operator
from std/times import toUnix
from std/uri import parseUri, initUri, UriParseError
from schedule import createSchedulerFromTodos
from taskman import start
import std/asyncfutures
import notifications
import types
import markdown_analyzer
import logger

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
    logError(e.msg)
    quit(QuitFailure)
  if parsedUrl.scheme != "https" and parsedUrl.scheme != "http":
    logError("Url " & input_url & " is not of type http or https.")
    quit(QuitFailure)

  let url = $parsedUrl

  # main functionality ---------------------------------------------------------
  var modifiedDates: ref Table[string, int64] = new(Table[string, int64])
  var todos: TodoTable = TodoTable()
  todos = makeTodoTable(root, modifiedDates, todos)
  var notifier = createSchedulerFromTodos(todos, url)
  asyncCheck start(notifier)

  while true:
    for file in todos.files:
      # check if the files have changed using last modified date
      if modifiedDates.contains(file):
        if (modifiedDates[file] == getFileInfo(file).lastWriteTime.toUnix()):
          continue
        else:
          log("file change detected...")
      else:
        # new file whose modified dates have not yet been saved, remake the db
        log("new file found: " & file)

      # reset the notifications schedule
      todos = makeTodoTable(root, modifiedDates, todos)
      notifier = createSchedulerFromTodos(todos, url)
      asyncCheck start(notifier)

    # "refresh rate"
    sleep(500)
  
  quit(QuitSuccess)


main()
