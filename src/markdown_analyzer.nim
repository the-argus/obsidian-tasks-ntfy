import std/os
import std/tables
import std/times
import markdown
import types
import files
import logger
import std/logging

proc collectTodos*(file: string): seq[Todo] =
  var todos: seq[Todo] = newSeq[Todo](0)
  return todos

proc makeTodoTable*(root: string, modifiedDates: ref Table[string, int64], previous: TodoTable): TodoTable =
  let allFiles: seq[string] = retrieveAllMarkdownFiles(root)
  var todosByFile: Table[string, seq[Todo]] = initTable[string, seq[Todo]]()
  var finalTable: TodoTable = TodoTable()
  finalTable.files = allFiles

  # collect all todos by concatenating to the sequence.
  for file in allFiles:
    if !modifiedDates.contains(file):
      # 
    let last_recorded_edit: int = modifiedDates[file]
    let last_edit int = getFileInfo(file).lastWriteTime.toUnix()

    if last_recorded_edit == last_edit:
      continue

    # store the last modified date for later comparison
    modifiedDates[file] = last_edit
    nt_logger.log(lvlInfo, "analyzing " & file & " for TODOs.")
    todosByFile[file] = collectTodos(file)

  finalTable.allTodos = allTodos

  return finalTable
