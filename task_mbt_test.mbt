///| Blackbox tests for task_mbt
///| Tests run against the package's public API

///|

///| Test: Parse simple Taskfile
#[test]
fn test_parse_simple_taskfile() {
  let yaml = "version: \"3\"\ntasks:\n  hello:\n    cmd: echo hello"
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(taskfile) => {
      // Check if tasks map has "hello"
      match Map::get(taskfile.tasks, "hello") {
        None => panic("hello task not found")
        Some(_) => ()
      }
    }
    Err(e) => {
      panic("Failed to parse simple Taskfile: " + e)
    }
  }
}

///|

///| Test: Parse Taskfile with dependencies
#[test]
fn test_parse_deps() {
  let yaml = "version: \"3\"\ntasks:\n  default:\n    deps: [d1, d2]\n  d1:\n    cmd: echo d1\n  d2:\n    cmd: echo d2"
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(taskfile) => {
      // Check default task has dependencies
      match Map::get(taskfile.tasks, "default") {
        None => panic("default task not found")
        Some(task) => {
          // Check deps array length
          assert_true(task.deps.size() == 2)
        }
      }
    }
    Err(e) => {
      panic("Failed to parse Taskfile with deps: " + e)
    }
  }
}

///|

///| Test: Parse Taskfile with description
#[test]
fn test_parse_desc() {
  let yaml = "version: \"3\"\ntasks:\n  build:\n    desc: Build the project\n    cmd: echo build"
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(taskfile) => {
      match Map::get(taskfile.tasks, "build") {
        None => panic("build task not found")
        Some(task) => {
          match task.desc {
            None => panic("description not found")
            Some(desc) => {
              assert_eq(desc, "Build the project")
            }
          }
        }
      }
    }
    Err(e) => {
      panic("Failed to parse Taskfile with desc: " + e)
    }
  }
}

///|

///| Test: Parse invalid YAML
#[test]
fn test_parse_invalid_yaml() {
  let yaml = "invalid: yaml: :"
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(_) => {
      panic("Should fail to parse invalid YAML")
    }
    Err(_) => {
      // Expected
    }
  }
}

///|

///| Test: Parse empty Taskfile
#[test]
fn test_parse_empty_taskfile() {
  let yaml = "version: \"3\""
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(taskfile) => {
      // Check tasks map is empty
      match Map::get(taskfile.tasks, "nonexistent") {
        None => ()  // Expected
        Some(_) => panic("Should be empty")
      }
    }
    Err(e) => {
      panic("Failed to parse empty Taskfile: " + e)
    }
  }
}

///|

///| Test: Parse Taskfile with version
#[test]
fn test_parse_version() {
  let yaml = "version: \"3\"\ntasks: {}"
  
  let result = parse_taskfile(yaml)
  
  match result {
    Ok(taskfile) => {
      match taskfile.version {
        None => panic("version not found")
        Some(v) => {
          assert_true(v.major == 3)
        }
      }
    }
    Err(e) => {
      panic("Failed to parse Taskfile with version: " + e)
    }
  }
}
