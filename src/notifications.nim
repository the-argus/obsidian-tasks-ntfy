from std/osproc import execProcess, poUsePath
from std/times import DateTime

type
  Notification* = object
    message: string
    date: DateTime
    url: string

  NoNotificationError* = object of ValueError

proc `==`*(a, b: Notification): bool =
  return (a.message == b.message) and (a.date == b.date)

proc notification(message: string, date: DateTime, url: string): Notification =
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

proc notify*(notification: Notification) =
  notify(notification.message, notification.url)
