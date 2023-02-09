import std/times
import std/tables
import regex

# taken from https://github.com/obsidian-tasks-group/obsidian-tasks/blob/main/src/Task.ts
let recurrenceSymbol* = '🔁'
let startDateSymbol* = '🛫'
let scheduledDateSymbol* = '⏳'
let dueDateSymbol* = '📅'
let doneDateSymbol* = '✅'
let priorityRegex* = re'([⏫🔼🔽])$/u'
let startDateRegex* = re'🛫 *(\d{4}-\d{2}-\d{2})$/u'
let scheduledDateRegex* = re'[⏳⌛] *(\d{4}-\d{2}-\d{2})$/u'
let dueDateRegex* = re'[📅📆🗓] *(\d{4}-\d{2}-\d{2})$/u'
let doneDateRegex* = re'✅ *(\d{4}-\d{2}-\d{2})$/u'
let recurrenceRegex* = re'🔁 ?([a-zA-Z0-9, !]+)$/iu'
let hashTags* = re'(^|\s)#[^ !@#$%^&*(),.?":{}|<>]*'

type
  Priority* {.pure.} = enum
    High, Medium, None, Low

  Recurrence* {.pure.} = enum
    # rrule: RRule
    baseOnToday: bool
    referenceDate: times.Time
    startDate: times.Time
    scheduledDate: times.Time
    dueDate: times.Time

  Todo* = object
    priority*: Priority
    status*: Status
    description*: string
    priority*: Priority
    startDate*: times.Time
    scheduledDate*: times.Time
    dueDate*: times.Time
    doneDate*: times.Time
    recurrence*: Recurrence
    tags*: seq[string]
    # originalMarkdown: string
    # scheduledDateIsInferred: bool

  TodoTable* = object
    # Todos sorted by how soon their deadlines are
    schedule*: seq[Todo]
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

proc nextTodo(todoTable: TodoTable): Todo =
  return todoTable.schedule[0]

let prioritySymbols* = initTable([Priority, string])
prioritySymbols[Priority.High] = '⏫'
prioritySymbols[Priority.Medium] = '🔼'
prioritySymbols[Priority.Low] = '🔽'
prioritySymbols[Priority.None] = ''
