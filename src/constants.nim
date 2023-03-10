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
let recurrenceSymbol* = "π"
let startDateSymbol* = "π«"
let scheduledDateSymbol* = "β³"
let dueDateSymbol* = "π"
let doneDateSymbol* = "β"
# regexs are different: no $ at the end to allow for additional whitespace and
# to let the dates be in an arbitrary order
let priorityRegex* = re"(?u)([β«πΌπ½])"
let startDateRegex* = re"(?u)(π« *(\d{4}-\d{2}-\d{2}))"
let scheduledDateRegex* = re"(?u)([β³β] *(\d{4}-\d{2}-\d{2}))"
let dueDateRegex* = re"(?u)([πππ] *(\d{4}-\d{2}-\d{2}))"
let doneDateRegex* = re"(?u)(β *(\d{4}-\d{2}-\d{2}))"
let recurrenceRegex* = re"(?iu)(π ?([a-zA-Z0-9, !]+))"
let statusRegex* = re"(?u)(\[([ xX\-/])\]\sTODO\s)"
let dateRegex* = re"(\d{4})-(\d{2})-(\d{2})"
# let hashTags* = (?u:re"(^|\s)#[^ !@#$%^&*(),.?\"\:{}|<>]*")

let prioritySymbols* = {
  "β«": Priority.High,
  "πΌ": Priority.Medium,
  "π½": Priority.Low,
  "": Priority.None
}.toTable

# IF YOU CHANGE THIS YOU MUST ALSO CHANGE THE REGEX
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
