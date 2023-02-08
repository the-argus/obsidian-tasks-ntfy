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

proc makeTodoTable*(root: string, modifiedDates: ref Table[string, int64]): TodoTable =
  let allFiles: seq[string] = retrieveAllMarkdownFiles(root)
  var allTodos: seq[Todo] = newSeq[Todo](0)
  var finalTable: TodoTable = TodoTable()
  finalTable.files = allFiles

  # collect all todos by concatenating to the sequence.
  for file in allFiles:
    # store the last modified date for later comparison
    modifiedDates[file] = getFileInfo(file).lastWriteTime.toUnix()
    nt_logger.log(lvlInfo, "analyzing " & file & " for TODOs.")
    allTodos &= collectTodos(file)

  return finalTable
