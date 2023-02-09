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

  while true:
    sendNotificationsIfNeeded(todos, url)

    for file in todos.files:
      # check if the files have changed using last modified date
      if modifiedDates.contains(file):
        if (modifiedDates[file] != getFileInfo(file).lastWriteTime.toUnix()):
          nt_logger.log(lvlInfo, "file change detected...")
          todos = makeTodoTable(root, modifiedDates, todos)
      else:
        # new file whose modified dates have not yet been saved, remake the db
        nt_logger.log(lvlInfo, "new file found: " & file)
        todos = makeTodoTable(root, modifiedDates, todos)

    # refresh rate
    os.sleep(500)
  
  quit(QuitSuccess)


main()
