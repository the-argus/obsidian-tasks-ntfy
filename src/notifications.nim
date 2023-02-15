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

proc initNotification*(message: string, date: DateTime, url: string): Notification =
  Notification(message:message, date:date, url:url)

proc notify(description: string, ntfyUrl: string) =
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
  return () => notify(notification.message, notification.url)
