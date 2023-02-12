import std/os
import std/tables
import std/lists
import std/algorithm
from std/times import dateTime, DateTime, toUnix, MonthdayRange, Month, local
import std/times # for DateTime < operator
import std/strutils
import std/options
import sugar
import markdown
import regex
import types
import files
import logger
import std/logging
import symbols

let defaultReminderHour = 9

proc toDateTime(rm: RegexMatch): times.DateTime =
  # all the regexes use group(1) as the regex match
  let date = $rm.group(1)
  var dateMatch: RegexMatch = RegexMatch()
  discard regex.find(date, dateRegex, dateMatch)
  let year = ($dateMatch.group(1)).parseInt()
  let month = ($dateMatch.group(2)).parseInt()
  let day: MonthdayRange = ($dateMatch.group(3)).parseInt()

  let newDateTime: times.DateTime = dateTime(
    year=year,
    month=Month(month),
    monthday=day,
    hour=defaultReminderHour,
    zone=local()
  )

  return newDateTime

proc toTodo(token: markdown.Token): Todo =
  var matchTarget = token.doc

  # get the priority and remove it
  var priorityMatch: RegexMatch = RegexMatch()
  let hasPriority: bool = regex.find(matchTarget, priorityRegex, priorityMatch)
  var priority = Priority.None
  if hasPriority:
    priority = prioritySymbols[$priorityMatch.group(0)]

  matchTarget = matchTarget.replace($priorityMatch.group(0), "")

  # get the status and remove it
  var statusMatch: RegexMatch = RegexMatch()
  discard regex.find(matchTarget, statusRegex, statusMatch)
  let status: Status = statusSymbols[$statusMatch.group(1)]

  matchTarget = matchTarget.replace($statusMatch.group(0), "")

  # make times
  var doneDateMatch: RegexMatch = RegexMatch()
  let hasDoneDate = regex.find(matchTarget, doneDateRegex, doneDateMatch)
  var doneDate: Option[DateTime] = none(DateTime)
  if hasDoneDate:
    matchTarget = matchTarget.replace($doneDateMatch.group(0), "")
    doneDate = some(doneDateMatch.toDateTime())
  
  var dueDateMatch: RegexMatch = RegexMatch()
  let hasDueDate = regex.find(matchTarget, dueDateRegex, dueDateMatch)
  var dueDate: Option[DateTime] = none(DateTime)
  if hasDueDate:
    matchTarget = matchTarget.replace($dueDateMatch.group(0), "")
    dueDate = some(dueDateMatch.toDateTime())
  
  var scheduledDateMatch: RegexMatch = RegexMatch()
  let hasScheduledDate = regex.find(matchTarget, scheduledDateRegex, scheduledDateMatch)
  var scheduledDate: Option[DateTime] = none(DateTime)
  if hasScheduledDate:
    matchTarget = matchTarget.replace($scheduledDateMatch.group(0), "")
    scheduledDate = some(scheduledDateMatch.toDateTime())
  
  var startDateMatch: RegexMatch = RegexMatch()
  let hasStartDate = regex.find(matchTarget, startDateRegex, startDateMatch)
  var startDate: Option[DateTime] = none(DateTime)
  if hasStartDate:
    matchTarget = matchTarget.replace($startDateMatch.group(0), "")
    startDate = some(startDateMatch.toDateTime())

  let todo = Todo(
    priority: priority,
    status: status,
    description: "",
    recurrence: none(Recurrence),
    startDate: startDate,
    dueDate: dueDate,
    doneDate: doneDate,
    scheduledDate: scheduledDate
  )

  return todo


proc isTodo(token: markdown.Token): bool =
  if token of markdown.Li:
    let pattern = re"(?u)\[[ xX\-/]\]\s*?TODO\s*?(.*?)"
    return pattern in token.doc
  return false


proc isUl(token: markdown.Token): bool =
  return token of markdown.Ul


proc recursiveMarkdownSearch(token: markdown.Token, eval: (Token) -> bool, allTokens: ref seq[Token]) =
  for child in token.children.items():
    if child of markdown.Inline:
      continue
    if child.eval():
      allTokens[].add(child)
    else:
      recursiveMarkdownSearch(child, eval, allTokens)


# get all the todos in a markdown file
proc collectTodos(file: string): seq[Todo] =
  var todos: seq[Todo] = newSeq[Todo](0)

  let root = markdown.Document()
  let config = initCommonmarkConfig()
  let state = markdown.State(config: config)

  let fileObject = open(file)
  defer: fileObject.close()

  # bring the file"s text into markdown parser
  root.doc = fileObject.readAll()

  # parse it
  state.parse(root)

  let allTodos: ref seq[Token] = new(seq[Token])
  let allUls: ref seq[Token] = new(seq[Token])

  # search for unordered lists
  recursiveMarkdownSearch(root, isUl, allUls)

  # search for TODOs inside those
  for ul in allUls[]:
    recursiveMarkdownSearch(ul, isTodo, allTodos)

  for todo in allTodos[]:
    nt_logger.log(lvlInfo, todo.doc)

  return todos


# compares two todos and returns the sooner one
proc timeSorter(x, y: Todo): int =
  if (not x.scheduledDate.isSome) and (not y.scheduledDate.isSome):
    # no dates provided!
    return 0
  if not y.scheduledDate.isSome:
    # x has a date which means it's more urgent
    return -1
  if not x.scheduledDate.isSome:
    # y has a date which means it's more urgent
    return 1

  # actual comparison
  if x.scheduledDate.get() < y.scheduledDate.get():
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
