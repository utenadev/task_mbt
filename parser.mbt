///| Taskfile Parser - YAML → Taskfile

///|

///| Parse a Taskfile YAML string
pub fn parse_taskfile(yaml_str: String) -> Result[Taskfile, String] {
  let yaml_docs = @yaml.Yaml::load_from_string(yaml_str) catch {
    e => return Err("Failed to parse YAML")
  }
  
  match yaml_docs {
    [] => Err("No YAML documents found")
    [yaml, ..] => {
      yaml_to_taskfile(yaml)
    }
  }
}

///|

fn yaml_to_taskfile(yaml: @yaml.Yaml) -> Result[Taskfile, String] {
  match yaml {
    @yaml.Yaml::Map(m) => {
      // Parse version
      let version = match m["version"] {
        @yaml.Yaml::String(v) => Some(parse_version(v))
        _ => None
      }
      
      // Parse tasks
      let tasks = match m["tasks"] {
        @yaml.Yaml::Map(tasks_map) => parse_tasks(tasks_map)
        _ => Map::new()
      }
      
      Ok(Taskfile:: {
        location: "",
        version: version,
        output: Output:: { style: None, group: None },
        method: None,
        includes: Includes:: { includes: Map::new() },
        vars: None,
        env: None,
        tasks: tasks,
        silent: false,
        dotenv: [],
        run: None,
        set: [],
        shopt: []
      })
    }
    _ => Err("Taskfile must be a YAML map")
  }
}

///|

fn parse_version(v: String) -> Version {
  Version:: {
    major: 3,
    minor: 0,
    patch: 0
  }
}

///|

fn parse_tasks(tasks_map: Map[String, @yaml.Yaml]) -> Map[String, Task] {
  let result = Map::new()
  
  for task_entry in tasks_map {
    let (name, task_yaml) = task_entry
    match task_yaml {
      @yaml.Yaml::Map(task_map) => {
        let task = parse_task(name, task_map)
        result[name] = task
      }
      @yaml.Yaml::String(cmd) => {
        let cmds = [cmd_from_string(cmd)]
        let task = Task:: {
          name: name,
          cmds: cmds,
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
        result[name] = task
      }
      _ => ()
    }
  }
  
  result
}

///|

fn parse_task(name: String, task_map: Map[String, @yaml.Yaml]) -> Task {
  // Parse description
  let desc = match task_map["desc"] {
    @yaml.Yaml::String(desc) => Some(desc)
    _ => None
  }
  
  // Parse commands
  let cmds = match task_map["cmds"] {
    @yaml.Yaml::Array(cmds) => parse_cmds(cmds)
    _ => []
  }
  
  // Parse dependencies
  let deps = match task_map["deps"] {
    @yaml.Yaml::Array(deps) => parse_deps(deps)
    _ => []
  }
  
  // Parse directory
  let dir = match task_map["dir"] {
    @yaml.Yaml::String(dir) => Some(dir)
    _ => None
  }
  
  Task:: {
    name: name,
    cmds: cmds,
    deps: deps,
    desc: desc,
    aliases: [],
    sources: [],
    generates: [],
    status: [],
    dir: dir,
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

fn parse_cmds(cmds: Array[@yaml.Yaml]) -> Array[Cmd] {
  let result = []
  for cmd_yaml in cmds {
    match cmd_yaml {
      @yaml.Yaml::String(cmd) => {
        result.push(cmd_from_string(cmd))
      }
      _ => ()
    }
  }
  result
}

///|

fn parse_deps(deps: Array[@yaml.Yaml]) -> Array[Dep] {
  let result = []
  for dep_yaml in deps {
    match dep_yaml {
      @yaml.Yaml::String(task_name) => {
        result.push(dep_from_string(task_name))
      }
      _ => ()
    }
  }
  result
}
