import std/times
import std/tables

type
  Priority* {.pure.} = enum
    High, Medium, Low

  Todo* = object
    due*, start*: times.Time
    priority*: Priority

  TodoTable* = object
    entriesByHour*: Table[int, Todo]
    entriesByDayofWeek*: Table[int, Todo]
    entriesByDayofMonth*: Table[int, Todo]
    files*: seq[string]
