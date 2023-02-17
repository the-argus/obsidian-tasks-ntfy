from std/osproc import execProcess, poUsePath
from std/times import DateTime
from std/options import Option, isSome, get
import sugar

type
  Notification* = object
    message: string
    date: Option[DateTime]
    url: string

  NoNotificationError* = object of ValueError

proc `==`*(a, b: Notification): bool =
  return (a.message == b.message) and (a.date == b.date)

proc `$`*(n: Notification): string =
  result = n.message
  if n.date.isSome:
    result &= " at " & $n.date

proc initNotification*(message: string, date: Option[DateTime], url: string): Notification =
  Notification(message:message, date:date, url:url)

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
