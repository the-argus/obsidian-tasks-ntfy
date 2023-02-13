from std/times import DateTime, now
import std/times # for < operator between dates
from std/tables import Table, toTable
import std/tables # for the [key] lookup proc
from std/options import none, Option, isSome, get
from strformat import fmt
from regex import re, group, RegexMatch, find
from unicode import toLower
import logger
from std/logging import log, lvlInfo
import constants

type
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
    todosByFilename*: Table[string, seq[Todo]]
    files*: seq[string]

  RecurrenceError* = object of ValueError

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

proc sooner(a, b: Option[DateTime]): Option[DateTime] =
  if a.isSome and b.isSome:
    if a.get() < b.get():
      return a
    else:
      return b
  
  if a.isSome:
    return a
  if b.isSome:
    return b
  return a

proc soonestDate*(todo: Todo): DateTime =
  # TODO: factor in recurrence
  var soonest: Option[DateTime] = todo.startDate

  soonest = sooner(soonest, todo.dueDate)
  soonest = sooner(soonest, todo.doneDate)
  soonest = sooner(soonest, todo.scheduledDate)

  if soonest.isSome:
    return soonest.get()
  else:
    # no date has been supplied for this todo at all
    var target = now()
    let day = initDuration(days=1)
    if target.hour >= defaultReminderHour:
      target += day
    return dateTime(
      year=target.year,
      month=target.month,
      monthday=target.monthday,
      hour=HourRange(defaultReminderHour)
    )
