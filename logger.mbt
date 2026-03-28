///| Logger utilities for task_mbt

type LogLevel = String

pub const DEBUG : LogLevel = "DEBUG"
pub const INFO : LogLevel = "INFO"
pub const WARN : LogLevel = "WARN"
pub const ERROR : LogLevel = "ERROR"

pub const DEFAULT : String = ""
pub const RED : String = ""
pub const GREEN : String = ""
pub const YELLOW : String = ""
pub const MAGENTA : String = ""
pub const CYAN : String = ""
pub const RESET : String = ""

///| Simple logger
struct Logger {
  verbose: Bool
  color: Bool
}

///|

///| Create a new logger
pub fn new_logger(verbose: Bool, color: Bool) -> Logger {
  Logger:: { verbose: verbose, color: color }
}

///|

fn log(logger: Logger, level: LogLevel, color: String, message: String) -> Unit {
  let prefix = match level {
    DEBUG => "[DEBUG] "
    INFO => "[INFO] "
    WARN => "[WARN] "
    ERROR => "[ERROR] "
    _ => "[INFO] "
  }
  let full_message = if logger.color {
    color + prefix + message + RESET
  } else {
    prefix + message
  }
  println(full_message)
}

///|

///| Print a debug message
pub fn debug(logger: Logger, message: String) -> Unit {
  if logger.verbose {
    log(logger, DEBUG, CYAN, message)
  }
}

///|

///| Print an info message
pub fn info(logger: Logger, message: String) -> Unit {
  log(logger, INFO, DEFAULT, message)
}

///|

///| Print a warning message
pub fn warn(logger: Logger, message: String) -> Unit {
  log(logger, WARN, YELLOW, message)
}

///|

///| Print an error message
pub fn err(logger: Logger, message: String) -> Unit {
  log(logger, ERROR, RED, message)
}

///|

///| Print a message to stdout
pub fn out(logger: Logger, message: String) -> Unit {
  println(message)
}
