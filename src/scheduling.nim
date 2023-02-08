import std/osproc
import types

proc notify(message: string, ntfyUrl: string) =
  execProcess("curl", args=["-d", message, ntfyUrl])

proc sendNotificationsIfNeeded*(todos: TodoTable, ntfyUrl: string) =
  for todo in todos.allTodos:

