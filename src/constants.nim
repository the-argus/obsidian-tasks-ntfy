from regex import re
from std/tables import toTable

type
  DateEntry {.pure.} = enum
    Day, Week, Month, Year

  Status* {.pure.} = enum
    Done, InProgress, Cancelled, Empty, Todo

  Priority* {.pure.} = enum
    High, Medium, None, Low

export DateEntry

let defaultReminderHour* = 9
# taken from https://github.com/obsidian-tasks-group/obsidian-tasks/blob/main/src/Task.ts
let recurrenceSymbol* = "🔁"
let startDateSymbol* = "🛫"
let scheduledDateSymbol* = "⏳"
let dueDateSymbol* = "📅"
let doneDateSymbol* = "✅"
# regexs are different: no $ at the end to allow for additional whitespace and
# to let the dates be in an arbitrary order
let priorityRegex* = re"(?u)([⏫🔼🔽])"
let startDateRegex* = re"(?u)(🛫 *(\d{4}-\d{2}-\d{2}))"
let scheduledDateRegex* = re"(?u)([⏳⌛] *(\d{4}-\d{2}-\d{2}))"
let dueDateRegex* = re"(?u)([📅📆🗓] *(\d{4}-\d{2}-\d{2}))"
let doneDateRegex* = re"(?u)(✅ *(\d{4}-\d{2}-\d{2}))"
let recurrenceRegex* = re"(?iu)(🔁 ?([a-zA-Z0-9, !]+))"
let statusRegex* = re"(?u)(\[([ xX\-/])\]\sTODO\s)"
let dateRegex* = re"(\d{4})-(\d{2})-(\d{2})"
# let hashTags* = (?u:re"(^|\s)#[^ !@#$%^&*(),.?\"\:{}|<>]*")

let prioritySymbols* = {
  "⏫": Priority.High,
  "🔼": Priority.Medium,
  "🔽": Priority.Low,
  "": Priority.None
}.toTable

let statusSymbols* = {
  "x": Status.Done,
  "X": Status.Done,
  "/": Status.InProgress,
  "-": Status.Cancelled,
  "": Status.Empty,
  " ": Status.Todo
}.toTable

let dateEntry* = {
  "day": DateEntry.Day,
  "week": DateEntry.Week,
  "month": DateEntry.Month,
  "year": DateEntry.Year,
}.toTable
