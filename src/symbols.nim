import regex
import types

# taken from https://github.com/obsidian-tasks-group/obsidian-tasks/blob/main/src/Task.ts
let recurrenceSymbol* = '🔁'
let startDateSymbol* = '🛫'
let scheduledDateSymbol* = '⏳'
let dueDateSymbol* = '📅'
let doneDateSymbol* = '✅'
let priorityRegex* = (?u:re'([⏫🔼🔽])$')
let startDateRegex* = (?u:re'🛫 *(\d{4}-\d{2}-\d{2})$')
let scheduledDateRegex* = (?u:re'[⏳⌛] *(\d{4}-\d{2}-\d{2})$')
let dueDateRegex* = (?u:re'[📅📆🗓] *(\d{4}-\d{2}-\d{2})$')
let doneDateRegex* = (?u:re'✅ *(\d{4}-\d{2}-\d{2})$')
let recurrenceRegex* = (?iu:re'🔁 ?([a-zA-Z0-9, !]+)$')
let statusRegex* = (?u:re'\[([ xX-/])\].*?$')
let dateRegex* = re'(\d{4})-(\d{2})-(\d{2})'
let hashTags* = (?u:re'(^|\s)#[^ !@#$%^&*(),.?":{}|<>]*')

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
