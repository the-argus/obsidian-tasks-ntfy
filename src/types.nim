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
    startDate: times.DateTime
    hasStartDate: bool
    scheduledDate: times.DateTime
    hasScheduledDate: bool
    dueDate: times.DateTime
    hasDueDate: bool
    doneDate: times.DateTime
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

proc startDate*(todo: Todo): times.DateTime =
  if not todo.hasStartDate:
    raise TodoAccessError
  todo.startDate

proc scheduledDate*(todo: Todo): times.DateTime =
  if not todo.hasScheduledDate:
    raise TodoAccessError
  todo.scheduledDate

proc dueDate*(todo: Todo): times.DateTime =
  if not todo.hasDueDate:
    raise TodoAccessError
  todo.dueDate

proc doneDate*(todo: Todo): times.DateTime =
  if not todo.hasDoneDate:
    raise TodoAccessError
  todo.doneDate

proc initTodo(priority: Priority, status: Status, description: string,
              recurrence: Recurrence = nil,
              startDate: times.DateTime = nil,
              dueDate: times.DateTime = nil,
              doneDate: times.DateTime = nil,
              scheduledDate: times.DateTime = nil
              ): Todo =
  let todo = Todo(
    priority = priority,
    status = status,
    description = description,
    hasRecurrence = (recurrence != nil),
    recurrence = recurrence,
    hasStartDate = (startDate != nil),
    startDate = startDate,
    hasDueDate = (dueDate != nil)
    dueDate = dueDate,
    hasScheduledDate = (scheduledDate != nil)
    scheduledDate = scheduledDate,
    hasDoneDate = (doneDate != nil),
    doneDate = doneDate,
  )

  return todo
