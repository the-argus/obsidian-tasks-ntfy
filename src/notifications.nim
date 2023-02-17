from std/osproc import execProcess, poUsePath
from std/times import DateTime
import sugar

type
  Notification* = object
    message: string
    date: DateTime
    url: string

  NoNotificationError* = object of ValueError

proc `==`*(a, b: Notification): bool =
  return (a.message == b.message) and (a.date == b.date)

proc `$`*(n: Notification): string =
  return n.message & " at " & $n.date

proc initNotification*(message: string, date: DateTime, url: string): Notification =
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
