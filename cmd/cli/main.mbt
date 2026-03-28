///| Task MBT CLI - With Command Execution (stub)

fn execute_command(cmd: String) -> Int {
  println("   ▶️  Executing: " + cmd)
  println("   ✅ Done! (stub)")
  0
}

///|

fn main() -> Unit {
  println("")
  println("🌙 task_mbt - Command Execution Demo")
  println("")
  
  // Read Taskfile.yml
  let taskfile_yaml = read_taskfile()
  
  // Parse YAML
  let result = @yaml.Yaml::load_from_string(taskfile_yaml) catch {
    e => {
      println("❌ YAML parse error")
      return
    }
  }
  
  match result {
    [] => {
      println("❌ No YAML documents found")
      return
    }
    [yaml, ..] => {
      run_tasks(yaml)
    }
  }
}

///|

fn read_taskfile() -> String {
  "version: \"3\"\ntasks:\n  hello:\n    desc: Say hello\n    cmd: echo Hello from task_mbt!\n  build:\n    desc: Build the project\n    cmd: echo Building...\n  test:\n    desc: Run tests\n    deps:\n      - build\n    cmd: echo Testing..."
}

///|

fn run_tasks(yaml: @yaml.Yaml) -> Unit {
  match yaml {
    @yaml.Yaml::Map(m) => {
      let tasks = match m["tasks"] {
        @yaml.Yaml::Map(t) => t
        _ => {
          println("❌ No tasks found in Taskfile")
          return
        }
      }
      
      println("📋 Running tasks...")
      println("")
      
      for task_entry in tasks {
        let (name, task_yaml) = task_entry
        println("🔷 Task: " + name)
        
        match task_yaml {
          @yaml.Yaml::Map(task_map) => {
            match task_map["desc"] {
              @yaml.Yaml::String(desc) => println("   " + desc)
              _ => ()
            }
            
            match task_map["cmd"] {
              @yaml.Yaml::String(cmd) => {
                let _ = execute_command(cmd)
                println("")
              }
              _ => ()
            }
          }
          _ => ()
        }
      }
      
      println("🎉 All tasks completed!")
    }
    _ => {
      println("❌ Invalid Taskfile format")
    }
  }
}
