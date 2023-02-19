import std/options
from std/times import getTime
import std/times
from std/heapqueue import clear
import std/tables # for the lookup operator
import sugar # for () => syntax
import taskman
import taskman/cron
from types import TodoTable, Todo
import notifications
import constants
import logger

proc createCron(notification: Notification): taskman.Cron =
  # start by getting all possible cron inputs
  let date = notification.date.get()
  var minute = {0.MinuteRange}
  var hour = {defaultReminderHour.HourRange}
  var monthday = {date.monthday.MonthdayRange}
  var weekday = getDayOfWeek(date.monthday.MonthdayRange, Month(date.month), date.year)
  var month = {Month(date.month)}

  # this function should only be called if notification.recurrence isSome
  let recurrence = notification.recurrence.get()

  # remove certain cron inputs if it should repeat for those elements
  if recurrence == DateEntry.Day:
    return initCron(minutes=minute, hours=hour)
  elif recurrence == DateEntry.Week:
    return initCron(minutes=minute, hours=hour, weekDays={weekday})
  elif recurrence == DateEntry.Month:
    return initCron(minutes=minute, hours=hour, monthDays=monthday)
  elif recurrence == DateEntry.Year:
    return initCron(minutes=minute, hours=hour, monthDays=monthday, months=month)

  # this should never happen >:(
  raise newException(ValueError, "createCron called on a notification with no known recurrence.")

proc createNotifications(todo: Todo, url: string): seq[Notification] =
  var notifications: seq[Notification] = @[]
  var startDate = todo.startDate.isSome
  var scheduledDate = todo.scheduledDate.isSome
  var dueDate = todo.dueDate.isSome
  
  if (not startDate) and (not scheduledDate) and (not dueDate):
    notifications.add(initNotification(todo.description, none(DateTime), url))
    return notifications
  
  if startDate:
    let n = initNotification(todo.description, todo.startDate, url)
    notifications.add(n)
    startDate = true
  if scheduledDate:
    let n = initNotification(todo.description, todo.scheduledDate, url)
    notifications.add(n)
    scheduledDate = true
  if dueDate:
    let n = initNotification(todo.description, todo.dueDate, url)
    notifications.add(n)
    dueDate = true

  return notifications

proc add(notifier: var AsyncScheduler, notifications: seq[Notification]) =
  # todos can have multiple notifications
  for notification in notifications:
    echo $notification
    # default is to notify every day at defaultReminderHour
    var task : AsyncTask = taskman.newTask[taskman.AsyncTaskHandler](initCron({0.MinuteRange}, {defaultReminderHour.HourRange}), notification.notifyFunc())
    if not notification.date.isSome:
      notifier &= task
      continue

    # handle recurrence with a cron timer
    if notification.recurrence.isSome:
      let cronTiming = createCron(notification)
      task = taskman.newTask[taskman.AsyncTaskHandler](cronTiming, notification.notifyFunc())
    else:
      # use datetime task if there is no recurrence
      task = taskman.newTask[taskman.AsyncTaskHandler](notification.date.get(), notification.notifyFunc())

    # register this notification task with the notifier
    notifier &= task

proc createTasksFromTodos*(notifier: var taskman.AsyncScheduler, todoTable: TodoTable, url: string) =
  notifier.tasks.clear()
  # create tasks for every todo
  for filename, todos in pairs(todoTable.todosByFilename):
    for todo in todos:
      let notifications = todo.createNotifications(url)
      notifier.add(notifications)
