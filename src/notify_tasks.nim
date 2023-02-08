import std/os
import std/strutils
import std/tables
import std/times
import types
import markdown_analyzer
import scheduling

proc main() =
  # process and validate arguments ---------------------------------------------
  if paramCount() < 1:
    echo("notify-tasks requires one positional argument: the root directory of your markdown vault.")
    quit(QuitFailure)
  elif paramCount() > 1:
    echo("Warning: notify-tasks only accepts one argument. Ignoring everything after " & paramStr(1))
  
  # first argument is the root directory
  let root = paramStr(1)
  if dirExists(root) != true:
    echo(root & " is not a valid directory.")
    quit(QuitFailure)

  # main functionality ---------------------------------------------------------
  var modifiedDates: ref Table[string, int64] = new(Table[string, int64])
  var todos: TodoTable = makeTodoTable(root, modifiedDates)

  while true:
    discard sendNotificationsIfNeeded(todos)

    for file in todos.files:
      # check if the files have changed using last modified date
      if modifiedDates.contains(file):
        if (modifiedDates[file] != getFileInfo(file).lastWriteTime.toUnix()):
          echo("file change detected...")
          todos = makeTodoTable(root, modifiedDates)
      else:
        # new file whose modified dates have not yet been saved, remake the db
        echo("new file found: " & file)
        todos = makeTodoTable(root, modifiedDates)

    # refresh rate
    os.sleep(500)
  
  quit(QuitSuccess)


main()
