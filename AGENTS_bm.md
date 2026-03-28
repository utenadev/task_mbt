# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
  `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod.json` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
  `find-references`. See $moonbit-agent-guide for details.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
  are stable or very unlikely to change. Use snapshot tests to record current
  behavior. For solid, well-defined results (e.g. scientific computations),
  prefer assertion tests. You can use `moon coverage analyze > uncovered.log` to
  see which parts of your code are not covered by tests.

## Native CLI Development Patterns (from actrun)

### Main Function Signature
```moonbit
async fn main(cli_args : Array[String]) -> Int {
  if cli_args.length() < 2 {
    println(usage_text())
    return 0
  }
  let command = cli_args[1]
  match command {
    "init" => handle_init_command()
    "create" => handle_create_command(cli_args)
    // ...
    _ => {
      println("unknown command: " + command)
      1
    }
  }
}
```

### CLI Argument Parsing Pattern
```moonbit
struct CliParseResult {
  options : CliOptions?
  errors : Array[String]
}

fn parse_cli_args(args : Array[String]) -> CliParseResult {
  let errors : Array[String] = []
  let mut workflow_path = ""
  let mut index = 1
  
  while index < args.length() {
    let arg = args[index]
    if arg == "--dry-run" { dry_run = true; index += 1; continue }
    if arg == "--repo" {
      if index + 1 >= args.length() { 
        errors.push("missing value for " + arg)
        break 
      }
      repo_root = Some(args[index + 1])
      index += 2
      continue
    }
    index += 1
  }
  
  if errors.length() > 0 { return { options: None, errors } }
  { options: Some({ workflow_path, repo_root, ... }), errors }
}
```

### Error Handling Pattern
- Use `struct { options : T?, errors : Array[String] }` for CLI parsing results
- Accumulate errors in an array, return all at once
- Use `try/catch/noraise` for exception handling:
  ```moonbit
  let content = try @xfs.read_file_to_string(config_path)
  catch { _ => return default_config() }
  noraise { value => value }
  ```

### Module Imports (moon.pkg)
```moonpkg
import {
  "moonbitlang/x/sys" @xsys,
  "moonbitlang/x/fs" @xfs,
  "moonbitlang/core/env" @env,
  "moonbitlang/core/json" @json,
  "moonbitlang/core/strconv" @strconv,
  "moonbitlang/async",
}
```

### Useful Packages
- `moonbitlang/x/sys` (@xsys): System operations (env vars, exit codes)
- `moonbitlang/x/fs` (@xfs): Filesystem operations
- `moonbitlang/core/env` (@env): Environment variables, current directory
- `moonbitlang/async`: Async runtime
- `moonbit-community/sqlite3`: SQLite bindings

### moon.mod.json Configuration
```json
{
  "name": "username/project",
  "version": "0.1.0",
  "deps": {
    "moonbitlang/x": "0.4.40",
    "moonbitlang/async": "0.16.6"
  },
  "preferred-target": "native",
  "source": "src"
}
```

## Migration Notes: Rust to MoonBit

### Key Differences

| Aspect | Rust | MoonBit |
|--------|------|---------|
| **Error Handling** | `Result<T, E>`, `?` operator | `Result<T, E>`, `try/catch/noraise` |
| **Pattern Matching** | `match` with `=>` | `match` with `=>` |
| **Generics** | `<T>` | `[T]` |
| **Visibility** | `pub`, `priv` | `pub`, `priv`, `pub(all)` |
| **Memory** | Ownership, borrowing | Reference counting |
| **Build System** | Cargo | Moon |

### Common Pitfalls

1. **Struct Initialization**: Use `Struct::{ field: value }` syntax
2. **Array Operations**: `Array::push(arr, elem)` returns `Unit`, not the array
3. **Try/Catch**: Must use parentheses in `if`/`while`: `if (try expr() catch { ... })`
4. **Package Exports**: Must explicitly export in `moon.pkg.json`
5. **SQLite**: No `execute()` method, use `prepare` → `step` → `finalize` pattern

### SQLite Usage Pattern

```moonbit
// Correct pattern for executing SQL
let stmt = try storage.conn.prepare("INSERT INTO ... VALUES (?);") catch { 
  _ => return Result::Err("prepare failed") 
}
try stmt.bind(index=1, value) catch { 
  _ => return Result::Err("bind failed") 
}
try stmt.step_once() catch { 
  _ => return Result::Err("step failed") 
}
try stmt.finalize() catch { 
  _ => return Result::Err("finalize failed") 
}
```

### CI/CD Setup

GitHub Actions workflow for MoonBit:

```yaml
steps:
  - uses: actions/checkout@v4
  - name: Setup MoonBit
    uses: hustcer/setup-moonbit@v1
  - name: Update registry
    run: moon update
  - name: Build
    run: moon build cmd/main --target native
```

## Project-Specific Knowledge

### beads_mbt Architecture

- **CLI Entry Point**: `cmd/main/main.mbt`
- **Storage Layer**: `lib/storage.mbt` (SQLite via moonbit-community/sqlite3)
- **Data Models**: `lib/model.mbt` (Issue, Status, IssueType)
- **Utilities**: `lib/util.mbt` (ID generation)

### Implemented Commands

- `init` - Initialize workspace
- `create <title>` - Create issue
- `list` - List issues
- `show <id>` - Show issue details
- `update <id>` - Update issue
- `close <id>` - Close issue
- `ready` - Show actionable issues
- `defer <id>` - Defer issue

### Testing Strategy

- Whitebox tests: `*_wbtest.mbt` files
- Test runner: `lib/test_runner/`
- Currently disabled in CI (needs fixing)

## AI Agent Skills

This project includes [moonbitlang/skills](https://github.com/moonbitlang/skills) as a git submodule in `.skills/`.

### Available Skills

- `moonbit-agent-guide` - Guide for writing, refactoring, and testing MoonBit projects
- `moonbit-lang` - MoonBit language reference and coding conventions
- `moonbit-spec-test-development` - Create formal spec-driven APIs and test suites
- `moonbit-extract-spec-test` - Extract spec and tests from existing implementations
- `moonbit-c-binding` - Write bindings for C libraries using native FFI

### For Claude Code Users

Install the skills marketplace:
```bash
# In Claude Code CLI
/plugin
# → Add Marketplace
# → Input: moonbitlang/skills
```

Or use the local submodule directly - AI agents will discover and use these skills automatically.
