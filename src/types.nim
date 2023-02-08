import std/times
import std/tables

type
  Priority* {.pure.} = enum
    High, Medium, Low

  Todo* = object
    due*, start*: times.Time
    message*: string
    priority*: Priority

  TodoTable* = object
    # Todos sorted by how soon their deadlines are
    schedule*: seq[Todo]
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

proc nextTodo(todoTable: TodoTable): Todo =
  return todoTable.schedule[0]
