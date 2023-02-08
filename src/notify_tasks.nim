import std/os
import std/strutils
import std/tables
import std/times
import std/re
import markdown

type
  Priority* {.pure.} = enum
    High, Medium, Low

  Todo* = object
    due*, start*: times.Time
    priority*: Priority

  TodoTable* = object
    entriesByHour: Table[int, Todo]
    entriesByDayofWeek: Table[int, Todo]
    entriesByDayofMonth: Table[int, Todo]
    files: seq[string]

proc retrieveAllMarkdownFiles(root: string): seq[string] =
  var files: seq[string] = newSeq[string](0)

  for file in walkDirRec(root, relative=true):
    if file.lastPathPart().endsWith(".md"):
      files.add(file)

  return files

proc collectTodos(file: string): seq[Todo] =
  var todos: seq[Todo] = newSeq[Todo](0)
  return todos

proc makeTodoTable(root: string, modifiedDates: ref Table[string, int64]): TodoTable =
  let allFiles: seq[string] = retrieveAllMarkdownFiles(root)
  var allTodos: seq[Todo] = newSeq[Todo](0)
  var finalTable: TodoTable = TodoTable()
  finalTable.files = allFiles

  # collect all todos by concatenating to the sequence.
  for file in allFiles:
    # store the last modified date for later comparison
    modifiedDates[file] = getFileInfo(file).lastWriteTime.toUnix()
    echo("analyzing " & file & " for TODOs.")
    allTodos &= collectTodos(file)

  return finalTable

proc sendNotificationsIfNeeded(todos: TodoTable): bool =
  return false

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
