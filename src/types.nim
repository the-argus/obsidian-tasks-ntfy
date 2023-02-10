import std/times
import std/tables
import regex

type
  Status* {.pure.} = enum
    Done, InProgress, Cancelled, Empty, Todo

  Priority* {.pure.} = enum
    High, Medium, None, Low

  Recurrence* {.pure.} = object
    # rrule: RRule
    baseOnToday: bool
    referenceDate: times.DateTime
    startDate: times.DateTime
    scheduledDate: times.DateTime
    dueDate: times.DateTime

  Todo* = object
    priority*: Priority
    status*: Status
    description*: string
    startDate*: times.DateTime
    scheduledDate*: times.DateTime
    dueDate*: times.DateTime
    doneDate*: times.DateTime
    recurrence*: Recurrence
    # tags*: seq[string]
    # originalMarkdown: string
    # scheduledDateIsInferred: bool

  TodoTable* = object
    # Todos sorted by how soon their deadlines are
    schedule*: seq[Todo]
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

proc nextTodo*(todoTable: TodoTable): Todo =
  return todoTable.schedule[0]
