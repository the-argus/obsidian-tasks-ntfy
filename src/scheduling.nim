import std/osproc
import std/tables
import types

proc notify(description: string, ntfyUrl: string) =
  discard execProcess("curl", args=["-d", description, ntfyUrl], workingDir="", env=nil, options={poUsePath})

proc sendNotificationsIfNeeded*(todos: TodoTable, ntfyUrl: string) =
  discard

