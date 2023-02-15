from std/options import isSome
import std/tables # for the lookup operator
import sugar # for () => syntax
import taskman
import taskman/cron
from types import TodoTable, Todo
from notifications import notifyFunc, Notification

proc createCron(notification: Notification): taskman.Cron =
  #TODO
  return initCron()

proc createNotifications(todo: Todo): seq[Notification] =
  if todo.startDate.isSome:
    discard
  if todo.scheduledDate.isSome:
    discard
  if todo.dueDate.isSome:
    discard
  if todo.doneDate.isSome:
    discard

  let notifications: seq[Notification] = @[]

  return notifications

proc addTasksToNotifier(todo: Todo, notifier: var Scheduler) =
  # todos can have multiple notifications
  let notifications = createNotifications(todo)
  for notification in notifications:
    let cronTiming = createCron(notification)
    let task = taskman.newTask[TaskHandler](cronTiming, notification.notifyFunc())
    # register this notification task with the notifier
    notifier &= task

proc createSchedulerFromTodos*(todoTable: TodoTable): taskman.Scheduler =

  var notifier = taskman.newScheduler()
  
  # create tasks for every todo
  for filename, todos in pairs(todoTable.todosByFilename):
    for todo in todos:
      addTasksToNotifier(todo, notifier)

  return notifier
