import regex
import types

# taken from https://github.com/obsidian-tasks-group/obsidian-tasks/blob/main/src/Task.ts
let recurrenceSymbol* = '🔁'
let startDateSymbol* = '🛫'
let scheduledDateSymbol* = '⏳'
let dueDateSymbol* = '📅'
let doneDateSymbol* = '✅'
let priorityRegex* = re'([⏫🔼🔽])$/u'
let startDateRegex* = re'🛫 *(\d{4}-\d{2}-\d{2})$/u'
let scheduledDateRegex* = re'[⏳⌛] *(\d{4}-\d{2}-\d{2})$/u'
let dueDateRegex* = re'[📅📆🗓] *(\d{4}-\d{2}-\d{2})$/u'
let doneDateRegex* = re'✅ *(\d{4}-\d{2}-\d{2})$/u'
let recurrenceRegex* = re'🔁 ?([a-zA-Z0-9, !]+)$/iu'
let hashTags* = re'(^|\s)#[^ !@#$%^&*(),.?":{}|<>]*'

let prioritySymbols* = initTable([string, Priority])
prioritySymbols['⏫'] = Priority.High
prioritySymbols['🔼'] = Priority.Medium
prioritySymbols['🔽'] = Priority.Low
prioritySymbols[''] = Priority.None

let statusSymbols = initTable([string, Status])
statusSymbols['x'] = Status.Done
statusSymbols['X'] = Status.Done
statusSymbols['/'] = Status.InProgress
statusSymbols['-'] = Status.Cancelled
statusSymbols[''] = Status.Empty
statusSymbols[' '] = Status.Todo
