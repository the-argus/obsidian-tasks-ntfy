from std/times import DateTime
from std/tables import Table, toTable
import std/tables # for the [key] lookup proc
from std/options import none, Option
from strformat import fmt
from regex import re, group, RegexMatch, find
from unicode import toLower
import logger
from std/logging import log, lvlInfo

type
  DateEntry {.pure.} = enum
    Day, Week, Month, Year

  Status* {.pure.} = enum
    Done, InProgress, Cancelled, Empty, Todo

  Priority* {.pure.} = enum
    High, Medium, None, Low

  Recurrence* = object
    # rrule: RRule
    text: string
    every: DateEntry

  Todo* = object
    priority*: Priority
    status*: Status
    description*: string
    startDate*: Option[DateTime]
    scheduledDate*: Option[DateTime]
    dueDate*: Option[DateTime]
    doneDate*: Option[DateTime]
    recurrence*: Option[Recurrence]
    # tags*: seq[string]
    # originalMarkdown: string
    # scheduledDateIsInferred: bool

  TodoTable* = object
    # Todos sorted by how soon their deadlines are
    schedule*: seq[Todo]
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

  RecurrenceError* = object of ValueError

let dateEntry = {
  "day": DateEntry.Day,
  "week": DateEntry.Week,
  "month": DateEntry.Month,
  "year": DateEntry.Year,
}.toTable

proc recurrenceFromText*(recurrenceContent: string): Recurrence =
  # pass in all the text relating to the recurrence, excluding the recurrence
  # character/emoji
  
  var text = unicode.toLower(recurrenceContent)

  let primaryRegex = re"(?u)(\s*?every\s*?(day|week|month|year))"
  var primaryMatch = RegexMatch()
  let hasPrimaryRule = text.find(primaryRegex, primaryMatch)

  if not hasPrimaryRule:
    raise newException(RecurrenceError, "Recurrence \"" & text & "\" does not contain the word \"every\" followed by day, week, month, or year.")

  let every = dateEntry[primaryMatch.group(1, text)[0]]
  
  # remove what was matched so far
  # for parsing the "in January" or "on the 1st" element of recurrence
  # text.delete(primaryMatch.group(0)[0])

  return Recurrence(text:recurrenceContent, every:every)
