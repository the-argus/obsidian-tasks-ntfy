from std/osproc import execProcess, poUsePath
import std/times
from std/options import Option, isSome, get, none
from std/strformat import fmt
import sugar
import constants
import types

type
  Notification* = object
    message: string
    date*: Option[DateTime]
    url: string
    recurrence*: Option[DateEntry]

  NoNotificationError* = object of ValueError

proc `==`*(a, b: Notification): bool =
  return (a.message == b.message) and (a.date == b.date)

proc `$`*(n: Notification): string =
  result = n.message
  if n.date.isSome:
    let date = n.date.get()
    result &= " at " & (fmt"{date.year}-{date.month}-{date.monthday}")

proc initNotification*(message: string, date: Option[DateTime], url: string, recurrence = none(DateEntry)): Notification =
  Notification(message:message, date:date, url:url, recurrence:recurrence)

proc notify(description: string, ntfyUrl: string) =
  echo description
  discard execProcess("curl",
    args=[
      "-d",
      description,
      ntfyUrl
    ],
    workingDir="",
    env=nil,
    options={poUsePath}
  )

proc notifyFunc*(notification: Notification): proc =
  return proc () {.async.} = notify(notification.message, notification.url)
