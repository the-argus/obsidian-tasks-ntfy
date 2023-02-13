from std/logging import lvlInfo, lvlError, log, newConsoleLogger

var nt_logger* = newConsoleLogger(fmtStr="[$time] - $levelname: ")

proc log*(message: string) =
  nt_logger.log(lvlInfo, message)

proc logError*(message: string) =
  nt_logger.log(lvlError, message)
