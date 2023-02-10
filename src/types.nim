from std/times import DateTime
from std/tables import Table
from strformat import fmt

type
  Status* {.pure.} = enum
    Done, InProgress, Cancelled, Empty, Todo

  Priority* {.pure.} = enum
    High, Medium, None, Low

  Recurrence* {.pure.} = object
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
    startDate: DateTime
    hasStartDate: bool
    scheduledDate: DateTime
    hasScheduledDate: bool
    dueDate: DateTime
    hasDueDate: bool
    doneDate: DateTime
    hasDoneDate: bool
    recurrence: Recurrence
    hasRecurrence: bool
    # tags*: seq[string]
    # originalMarkdown: string
    # scheduledDateIsInferred: bool

  TodoTable* = object
    # Todos sorted by how soon their deadlines are
    schedule*: seq[Todo]
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

  TodoAccessError* = object of ValueError

proc nextTodo*(todoTable: TodoTable): Todo =
  return todoTable.schedule[0]

proc startDate*(todo: Todo): DateTime =
  if not todo.hasStartDate:
    raise newException(TodoAccessError, fmt"Todo does not have a start date.")
  todo.startDate

proc scheduledDate*(todo: Todo): DateTime =
  if not todo.hasScheduledDate:
    raise newException(TodoAccessError, fmt"Todo does not have a scheduled date.")
  todo.scheduledDate

proc dueDate*(todo: Todo): DateTime =
  if not todo.hasDueDate:
    raise newException(TodoAccessError, fmt"Todo does not have a due date.")
  todo.dueDate

proc doneDate*(todo: Todo): DateTime =
  if not todo.hasDoneDate:
    raise newException(TodoAccessError, fmt"Todo does not have a done date.")
  todo.doneDate

proc initTodo(priority: Priority, status: Status, description: string,
              recurrence: Recurrence = nil,
              startDate: DateTime = nil,
              dueDate: DateTime = nil,
              doneDate: DateTime = nil,
              scheduledDate: DateTime = nil
              ): Todo =
  let todo = Todo(
    priority = priority,
    status = status,
    description = description,
    hasRecurrence = (recurrence != nil),
    recurrence = recurrence,
    hasStartDate = (startDate != nil),
    startDate = startDate,
    hasDueDate = (dueDate != nil),
    dueDate = dueDate,
    hasScheduledDate = (scheduledDate != nil),
    scheduledDate = scheduledDate,
    hasDoneDate = (doneDate != nil),
    doneDate = doneDate,
  )

  return todo
