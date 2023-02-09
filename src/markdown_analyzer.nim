import std/os
import std/tables
import std/lists
import std/algorithm
import std/times
import markdown
import types
import files
import logger
import std/logging

proc isTodo(token: markdown.Token): bool =
  if token of Ul:
    nt_logger.log(lvlInfo, "TODO found in token with contents \"" & token.doc & "\"")
    return true
  return false

proc recursiveTodoSearch(token: markdown.Token, allTodos: var seq[Token]): seq[Token] =
  for child in token.children.items():
    if child.isTodo():
      allTodos.add(child)
    else:
      allTodos &= recursiveTodoSearch(child, allTodos)
  return allTodos

# get all the todos in a markdown file
proc collectTodos(file: string): seq[Todo] =
  var todos: seq[Todo] = newSeq[Todo](0)

  let root = markdown.Document()
  let config = initCommonmarkConfig()
  let state = markdown.State(config: config)

  let fileObject = open(file)
  defer: fileObject.close()

  # bring the file's text into markdown parser
  root.doc = fileObject.readAll()
  # parse it
  state.parse(root)

  var allTodos = newSeq[Token](0)
  allTodos = recursiveTodoSearch(root, allTodos)

  return todos

# compares two todos and returns the sooner one
proc timeSorter(x, y: Todo): int =
  if x.due < y.due:
    # x is sooner than y!
    return -1
  else:
    # arbitrarily return y if its sooner OR equal
    return 1

proc cleanupDeletedFiles(todoTable: TodoTable): Table[string, seq[Todo]] =
  var cleanedTable: Table[string, seq[Todo]] = initTable[string, seq[Todo]]()
  for file in todoTable.files:
      # copy over all the kv pairs of todosByFilename ONLY if they are
      # present in files
      cleanedTable[file] = todoTable.todosByFilename[file]
  return cleanedTable

proc cleanupDeletedFiles(modifiedDates: ref Table[string, int64], todos: TodoTable) =
  for file, modifiedDate in pairs(modifiedDates):
    if todos.todosByFilename.contains(file) != true:
      # the file has been moved or deleted
      modifiedDates.del(file)

proc makeTodoTable*(root: string, modifiedDates: ref Table[string, int64], previous: TodoTable): TodoTable =
  let allFiles: seq[string] = retrieveAllMarkdownFiles(root)
  var newTodos: Table[string, seq[Todo]] = initTable[string, seq[Todo]]()
  var finalTable = previous
  finalTable.files = allFiles
  var todosChanged = false

  # collect all todos by concatenating to the sequence.
  for file in allFiles:
    let last_edit: int64 = getFileInfo(file).lastWriteTime.toUnix()
    if modifiedDates.contains(file):
      # if file is unchanged, skip
      if modifiedDates[file] == last_edit:
        continue
    todosChanged = true
    # store the last modified date for next loop comparison
    modifiedDates[file] = last_edit
    nt_logger.log(lvlInfo, "analyzing " & file & " for TODOs.")
    newTodos[file] = collectTodos(file)

  if todosChanged:
    # variable to collect *every* todo in (sort later)
    var unsortedTodos: seq[Todo] = newSeq[Todo](0)

    # update the todos for edited files
    for filename, todos in pairs(newTodos):
      finalTable.todosByFilename[filename] = todos
      for todo in todos:
        unsortedTodos.add(todo)

    # do cleanup
    finalTable.todosByFilename = cleanupDeletedFiles(finalTable)
    cleanupDeletedFiles(modifiedDates, finalTable)

    # sort the schedule
    unsortedTodos.sort(timeSorter)
    finalTable.schedule = unsortedTodos # its sorted now though


  return finalTable
