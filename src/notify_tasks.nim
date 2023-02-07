import std/os
import std/strutils
import std/tables
import markdown

type
  Priority* {.pure.} = enum
    High, Medium, Low

  Todo* = object
    due*, start*: string
    priority*: Priority

  TodoTable* = object
    entriesByHour: Table[int, Todo]
    entriesByDayofWeek: Table[int, Todo]
    entriesByDayofMonth: Table[int, Todo]
    files: seq[string]

proc makeTodoTable(root: string): TodoTable =
  let allFiles: seq[string] = retrieveAllMarkdownFiles(root)
  var allTodos: seq[Todo] = @[]
  var finalTable: TodoTable = TodoTable()
  finalTable.files = allFiles

  # collect all todos by concatenating to the sequence.
  for file in allFiles:
    allTodos &= collectTodos(file)


proc main() =
  # process and validate arguments ---------------------------------------------
  if paramCount() < 1:
    echo("notify-tasks requires one positional argument: the root directory of your markdown vault.")
    quit(QuitFailure)
  elif paramCount() > 1:
    echo("Warning: notify-tasks only accepts one argument. Ignoring everything after " & paramStr(1))
  
  # first argument is the root directory
  let root = paramStr(1)
  if !dirExists(root):
    echo(root & " is not a valid directory.")
    quit(QuitFailure)

  # main functionality ---------------------------------------------------------
  TodoTable todos = makeTodoTable(root)
  Table modifiedDates = {}.newTable()

  while true:
    sendNotificationsIfNeeded(todos)

    for file in todos.files:
      if ()

    # refresh rate
    os.sleep(500)
  
  quit(QuitSuccess)


main()
