import std/osproc
import std/tables
import types

proc notify(description: string, ntfyUrl: string) =
  discard execProcess("curl", args=["-d", description, ntfyUrl], workingDir="", env=nil, options={poUsePath})

proc sendNotificationsIfNeeded*(todos: TodoTable, ntfyUrl: string) =
  for filename, todos in pairs(todos.todosByFilename):
    for todo in todos:
      notify(todo.description, ntfyUrl)

