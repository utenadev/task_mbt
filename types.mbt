///| Core types for task_mbt

///| Version information
struct Version {
  major: Int
  minor: Int
  patch: Int
}

///| A command to execute
struct Cmd {
  cmd: String
  task: Option[String]
  silent: Bool
  ignore_error: Bool
  defer_cmd: Bool
  vars: Option[Vars]
  platforms: Array[Platform]
}

///| A task dependency
struct Dep {
  task: String
  vars: Option[Vars]
  silent: Bool
}

///| A glob pattern for files
struct Glob {
  glob: String
  negate: Bool
}

///| Platform specification
struct Platform {
  os: Option[String]
  arch: Option[String]
}

///| A variable definition
struct Var {
  value: Option[String]
  sh: Option[String]
  ref_str: Option[String]
}

///| Collection of variables
struct Vars {
  vars: Map[String, Var]
}

///| A precondition for a task
struct Precondition {
  sh: String
  msg: Option[String]
}

///| Requirements for a task
struct Requires {
  vars: Array[String]
}

///| Output style
struct Output {
  style: Option[String]
  group: Option[Bool]
}

///| Include specification
struct Include {
  taskfile: String
  dir: Option[String]
  optional: Bool
  aliases: Array[String]
  vars: Option[Vars]
}

///| Collection of includes
struct Includes {
  includes: Map[String, Include]
}

///| A task definition
struct Task {
  name: String
  cmds: Array[Cmd]
  deps: Array[Dep]
  desc: Option[String]
  aliases: Array[String]
  sources: Array[Glob]
  generates: Array[Glob]
  status: Array[String]
  dir: Option[String]
  vars: Option[Vars]
  env: Option[Vars]
  silent: Option[Bool]
  interactive: Bool
  internal: Bool
  ignore_error: Bool
  platforms: Array[Platform]
  label: Option[String]
  summary: Option[String]
  precondition: Array[Precondition]
  requires: Option[Requires]
  dotenv: Array[String]
  run: Option[String]
  method: Option[String]
  set: Array[String]
  shopt: Array[String]
}

///| A Taskfile definition
struct Taskfile {
  location: String
  version: Option[Version]
  output: Output
  method: Option[String]
  includes: Includes
  vars: Option[Vars]
  env: Option[Vars]
  tasks: Map[String, Task]
  silent: Bool
  dotenv: Array[String]
  run: Option[String]
  set: Array[String]
  shopt: Array[String]
}

///|

///| Create a new empty Task
pub fn new_task(name: String) -> Task {
  Task:: {
    name: name,
    cmds: [],
    deps: [],
    desc: None,
    aliases: [],
    sources: [],
    generates: [],
    status: [],
    dir: None,
    vars: None,
    env: None,
    silent: None,
    interactive: false,
    internal: false,
    ignore_error: false,
    platforms: [],
    label: None,
    summary: None,
    precondition: [],
    requires: None,
    dotenv: [],
    run: None,
    method: None,
    set: [],
    shopt: []
  }
}

///|

///| Create a new empty Taskfile
pub fn new_taskfile() -> Taskfile {
  Taskfile:: {
    location: "",
    version: None,
    output: Output:: { style: None, group: None },
    method: None,
    includes: Includes:: { includes: Map::new() },
    vars: None,
    env: None,
    tasks: Map::new(),
    silent: false,
    dotenv: [],
    run: None,
    set: [],
    shopt: []
  }
}

///|

///| Create a new Cmd from a command string
pub fn cmd_from_string(cmd_str: String) -> Cmd {
  Cmd:: {
    cmd: cmd_str,
    task: None,
    silent: false,
    ignore_error: false,
    defer_cmd: false,
    vars: None,
    platforms: []
  }
}

///|

///| Create a new Dep from a task name
pub fn dep_from_string(task_name: String) -> Dep {
  Dep:: {
    task: task_name,
    vars: None,
    silent: false
  }
}
