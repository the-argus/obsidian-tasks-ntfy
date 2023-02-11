from std/times import DateTime
from std/tables import Table
from std/options import none, Option
from strformat import fmt

type
  Status* {.pure.} = enum
    Done, InProgress, Cancelled, Empty, Todo

  Priority* {.pure.} = enum
    High, Medium, None, Low

  Recurrence* = object
    # rrule: RRule
    baseOnToday: bool
    referenceDate: DateTime
    startDate: DateTime
    scheduledDate: DateTime
    dueDate: DateTime

  Todo* = object
    priority*: Priority
    status*: Status
    description*: string
    startDate*: Option[DateTime]
    scheduledDate*: Option[DateTime]
    dueDate*: Option[DateTime]
    doneDate*: Option[DateTime]
    recurrence*: Option[Recurrence]
    # tags*: seq[string]
    # originalMarkdown: string
    # scheduledDateIsInferred: bool

  TodoTable* = object
    # Todos sorted by how soon their deadlines are
    schedule*: seq[Todo]
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

  TodoAccessError* = object of ValueError
