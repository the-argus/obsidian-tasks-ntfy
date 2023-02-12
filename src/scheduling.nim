import std/osproc
import std/tables
import std/options
import types

proc notify*(description: string, ntfyUrl: string) =
  discard execProcess("curl", args=["-d", description, ntfyUrl], workingDir="", env=nil, options={poUsePath})

proc retrieveNextNotification*(todos: TodoTable, var notif: Notification): bool =
  # sort to find the soonest todo, return false if there are none
  var soonest: Option[Todo] = none(Todo)
  for filename, todo in pairs(todos.todosByFilename):
    let contender = todo.soonestDate()
    # skip this one if its later than the current
    if soonest.isSome:
      if soonest.get().soonestDate() < contender:
        continue

    # update soonest with the NEW soonest todo
    soonest = some(todo)

  if soonest.isSome:
    let next = soonest.get()
    notif = Notification(message=next.description, date=next.soonestDate())
    return true
  return false

