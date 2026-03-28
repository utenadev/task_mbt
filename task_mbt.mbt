///| Core executor for task_mbt

///| Executor configuration
priv struct ExecutorConfig {
  dir: String
  entrypoint: Option[String]
  force: Bool
  verbose: Bool
  silent: Bool
  dry: Bool
  parallel: Bool
  color: Bool
  timeout: Int
}

///|

///| Executor state
struct Executor {
  config: ExecutorConfig
  taskfile: Option[Taskfile]
  logger: Logger
}

///|

///| Create a new executor with default configuration
pub fn new_executor() -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: ".",
      entrypoint: None,
      force: false,
      verbose: false,
      silent: false,
      dry: false,
      parallel: false,
      color: true,
      timeout: 10000
    },
    taskfile: None,
    logger: new_logger(false, true)
  }
}

///|

///| Apply configuration options to the executor
pub fn with_dir(exec: Executor, dir: String) -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: dir,
      entrypoint: exec.config.entrypoint,
      force: exec.config.force,
      verbose: exec.config.verbose,
      silent: exec.config.silent,
      dry: exec.config.dry,
      parallel: exec.config.parallel,
      color: exec.config.color,
      timeout: exec.config.timeout
    },
    taskfile: exec.taskfile,
    logger: exec.logger
  }
}

///|

pub fn with_entrypoint(exec: Executor, entrypoint: String) -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: exec.config.dir,
      entrypoint: Some(entrypoint),
      force: exec.config.force,
      verbose: exec.config.verbose,
      silent: exec.config.silent,
      dry: exec.config.dry,
      parallel: exec.config.parallel,
      color: exec.config.color,
      timeout: exec.config.timeout
    },
    taskfile: exec.taskfile,
    logger: exec.logger
  }
}

///|

pub fn with_verbose(exec: Executor, verbose: Bool) -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: exec.config.dir,
      entrypoint: exec.config.entrypoint,
      force: exec.config.force,
      verbose: verbose,
      silent: exec.config.silent,
      dry: exec.config.dry,
      parallel: exec.config.parallel,
      color: exec.config.color,
      timeout: exec.config.timeout
    },
    taskfile: exec.taskfile,
    logger: new_logger(verbose, exec.logger.color)
  }
}

///|

pub fn with_silent(exec: Executor, silent: Bool) -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: exec.config.dir,
      entrypoint: exec.config.entrypoint,
      force: exec.config.force,
      verbose: exec.config.verbose,
      silent: silent,
      dry: exec.config.dry,
      parallel: exec.config.parallel,
      color: exec.config.color,
      timeout: exec.config.timeout
    },
    taskfile: exec.taskfile,
    logger: exec.logger
  }
}

///|

pub fn with_dry(exec: Executor, dry: Bool) -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: exec.config.dir,
      entrypoint: exec.config.entrypoint,
      force: exec.config.force,
      verbose: exec.config.verbose,
      silent: exec.config.silent,
      dry: dry,
      parallel: exec.config.parallel,
      color: exec.config.color,
      timeout: exec.config.timeout
    },
    taskfile: exec.taskfile,
    logger: exec.logger
  }
}

///|

pub fn with_color(exec: Executor, color: Bool) -> Executor {
  Executor:: {
    config: ExecutorConfig:: {
      dir: exec.config.dir,
      entrypoint: exec.config.entrypoint,
      force: exec.config.force,
      verbose: exec.config.verbose,
      silent: exec.config.silent,
      dry: exec.config.dry,
      parallel: exec.config.parallel,
      color: color,
      timeout: exec.config.timeout
    },
    taskfile: exec.taskfile,
    logger: new_logger(exec.logger.verbose, color)
  }
}

///|

///| Setup the executor
pub fn setup(exec: Executor) -> Result[Executor, String] {
  Ok(Executor:: {
    config: exec.config,
    taskfile: exec.taskfile,
    logger: exec.logger
  })
}

///|

///| Load Taskfile from YAML string
pub fn load_taskfile(exec: Executor, yaml_str: String) -> Result[Executor, String] {
  let parsed = parse_taskfile(yaml_str)
  match parsed {
    Err(e) => Err(e)
    Ok(taskfile) => {
      Ok(Executor:: {
        config: exec.config,
        taskfile: Some(taskfile),
        logger: exec.logger
      })
    }
  }
}

///|

///| Run a task by name
pub fn run_task(exec: Executor, task_name: String) -> Result[Executor, String] {
  match exec.taskfile {
    None => Err("Taskfile not loaded. Call load_taskfile() first.")
    Some(taskfile) => {
      match Map::get(taskfile.tasks, task_name) {
        None => Err("Task not found: " + task_name)
        Some(task) => {
          execute_task(exec, task)
        }
      }
    }
  }
}

///|

fn execute_task(exec: Executor, task: Task) -> Result[Executor, String] {
  // Print task description
  match task.desc {
    None => ()
    Some(desc) => info(exec.logger, "Task: " + task.name + " - " + desc)
  }
  
  // Execute dependencies first
  for dep in task.deps {
    let _ = execute_dep(exec, dep)
  }
  
  // Execute commands
  for cmd in task.cmds {
    let _ = execute_cmd(exec, cmd)
  }
  
  Ok(exec)
}

///|

fn execute_dep(exec: Executor, dep: Dep) -> Result[Executor, String] {
  debug(exec.logger, "Would execute dependency: " + dep.task)
  Ok(exec)
}

///|

fn execute_cmd(exec: Executor, cmd: Cmd) -> Result[Executor, String] {
  if exec.config.dry {
    info(exec.logger, "[DRY RUN] Would execute: " + cmd.cmd)
  } else {
    info(exec.logger, "Executing: " + cmd.cmd)
    // TODO: Actually execute shell command
  }
  Ok(exec)
}

///|

///| List all available tasks
pub fn list_tasks(exec: Executor) -> Result[Array[(String, Option[String])], String] {
  match exec.taskfile {
    None => Err("Taskfile not loaded. Call load_taskfile() first.")
    Some(taskfile) => {
      let result = []
      for entry in taskfile.tasks {
        let (name, task) = entry
        result.push((name, task.desc))
      }
      Ok(result)
    }
  }
}
