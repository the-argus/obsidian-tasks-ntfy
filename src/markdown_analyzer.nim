import std/os
import std/tables
import std/lists
import std/algorithm
import std/times
import std/strutils
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
    month=times.Month(month),
    monthday=day,
    hour=defaultReminderHour,
    zone=times.local()
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
  var doneDate: times.DateTime = nil
  if hasDoneDate:
    matchTarget = matchTarget.replace($doneDateMatch.group(0), "")
    doneDate = doneDateMatch.toDateTime()
  
  var dueDateMatch: RegexMatch = RegexMatch()
  let hasDueDate = regex.find(matchTarget, dueDateRegex, dueDateMatch)
  var dueDate: times.DateTime = nil
  if hasDueDate:
    matchTarget = matchTarget.replace($dueDateMatch.group(0), "")
    dueDate = dueDateMatch.toDateTime()
  
  var scheduledDateMatch: RegexMatch = RegexMatch()
  let hasScheduledDate = regex.find(matchTarget, scheduledDateRegex, scheduledDateMatch)
  var scheduledDate: times.DateTime = nil
  if hasScheduledDate:
    matchTarget = matchTarget.replace($scheduledDateMatch.group(0), "")
    scheduledDate = scheduledDateMatch.toDateTime()
  
  var startDateMatch: RegexMatch = RegexMatch()
  let hasStartDate = regex.find(matchTarget, startDateRegex, startDateMatch)
  var startDate: times.DateTime = nil
  if hasStartDate:
    matchTarget = matchTarget.replace($startDateMatch.group(0), "")
    startDate = startDateMatch.toDateTime()

  let todo = initTodo(
    priority,
    status,
    description = "",
    nil, # recurrence not working atm
    startDate,
    dueDate,
    doneDate,
    scheduledDate
  )

  return todo


proc isTodo(token: markdown.Token): bool =
  if token of markdown.Li:
    let pattern = re"(?u)\[[ x]\]\s*?TODO\s*?(.*?)$"
    return pattern in token.doc
  return false


proc isUl(token: markdown.Token): bool =
  return token of markdown.Ul


proc recursiveMarkdownSearch(token: markdown.Token, eval: (Token) -> bool, allTokens: ref seq[Token]) =
  for child in token.children.items():
    # skip small children that can"t even contain "- [ ] TODO"
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
  if x.scheduledDate < y.scheduledDate:
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
