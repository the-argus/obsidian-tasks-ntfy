from std/options import isSome, get
from std/times import getTime
import std/times
from std/heapqueue import clear
import std/tables # for the lookup operator
import sugar # for () => syntax
import taskman
import taskman/cron
from types import TodoTable, Todo
import notifications
import logger

proc createCron(notification: Notification): taskman.Cron =
  #TODO
  return initCron()

proc createNotifications(todo: Todo, url: string): seq[Notification] =
  var notifications: seq[Notification] = @[]
  
  if todo.startDate.isSome:
    let n = initNotification(todo.description, todo.startDate.get(), url)
    notifications.add(n)
  if todo.scheduledDate.isSome:
    let n = initNotification(todo.description, todo.scheduledDate.get(), url)
    notifications.add(n)
  if todo.dueDate.isSome:
    let n = initNotification(todo.description, todo.dueDate.get(), url)
    notifications.add(n)

  return notifications

proc add(notifier: var AsyncScheduler, notifications: seq[Notification]) =
  # todos can have multiple notifications
  for notification in notifications:
    let cronTiming = createCron(notification)
    let task = taskman.newTask[taskman.AsyncTaskHandler](cronTiming, notification.notifyFunc())
    # register this notification task with the notifier
    notifier &= task

proc createTasksFromTodos*(notifier: var taskman.AsyncScheduler, todoTable: TodoTable, url: string) =
  notifier.tasks.clear()
  # create tasks for every todo
  for filename, todos in pairs(todoTable.todosByFilename):
    for todo in todos:
      let notifications = todo.createNotifications(url)
      notifier.add(notifications)
