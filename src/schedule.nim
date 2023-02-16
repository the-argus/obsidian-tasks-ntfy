from std/options import isSome, get
from std/times import getTime
import std/tables # for the lookup operator
import sugar # for () => syntax
import taskman
import taskman/cron
from types import TodoTable, Todo
from notifications import notifyFunc, Notification, initNotification
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
  if todo.doneDate.isSome:
    let n = initNotification(todo.description, todo.doneDate.get(), url)
    notifications.add(n)

  return notifications

proc add(notifier: var AsyncScheduler, notifications: seq[Notification]) =
  # todos can have multiple notifications
  for notification in notifications:
    let cronTiming = createCron(notification)
    let task = taskman.newTask[taskman.AsyncTaskHandler](cronTiming, notification.notifyFunc())
    # register this notification task with the notifier
    notifier &= task

proc createSchedulerFromTodos*(todoTable: TodoTable, url: string): taskman.AsyncScheduler =
  var notifier = taskman.newAsyncScheduler()
  # create tasks for every todo
  for filename, todos in pairs(todoTable.todosByFilename):
    for todo in todos:
      let notifications = todo.createNotifications(url)
      notifier.add(notifications)

  return notifier
