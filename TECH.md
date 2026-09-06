# Task MBT - Technical Notes

## Project Overview

Port of [go-task/task](https://github.com/go-task/task) to MoonBit.

**go-task version**: v3 (latest)
**MoonBit version**: Latest stable

## Architecture Comparison

### Original Go Structure
```
go-task/
├── executor.go      # Main executor
├── task.go          # Task execution
├── setup.go         # Initialization
├── taskfile/
│   ├── reader.go    # Taskfile parsing
│   ├── node.go      # File/HTTP/Git nodes
│   └── ast/
│       ├── taskfile.go
│       ├── task.go
│       ├── cmd.go
│       └── var.go
├── internal/
│   ├── logger/
│   ├── output/
│   ├── execext/
│   └── fingerprint/
└── cmd/task/        # CLI entry point
```

### MoonBit Port Structure
```
task_mbt/
├── task_mbt.mbt          # Executor core
├── taskfile/
│   └── ast/
│       ├── task.mbt      # AST type definitions
│       └── helpers.mbt   # Constructors
├── internal/
│   └── logger/
│       └── logger.mbt    # Logging
└── cmd/task/
   └── main.mbt          # CLI
```

## Technical Insights

### 1. Package System

**Go**: `import "path/to/package"` to use

**MoonBit**: Define imports in `moon.pkg.json`, access via `@alias`

```json
{
  "import": [
    "utenadev/task_mbt/internal/logger"
  ]
}
```

```moonbit
// Usage - not slash but dot!
@logger.info(logger, "message")      // ✅ Correct
@logger/info(logger, "message")      // ❌ Wrong
```

### 1.5. Function Call Syntax

MoonBit is **space-separated** function calls, arguments in parentheses:

```moonbit
@yaml.Yaml::load_from_string(yaml_str)     // ✅ Correct
@yaml.Yaml::load_from_string yaml_str      // ❌ Wrong (sometimes works)
@logger.new_logger(verbose, color)         // ✅ Correct
```

### 2. Type System Differences

#### Go Struct
```go
type Task struct {
   Name string
   Cmds []*Cmd
}
```

#### MoonBit Struct
```moonbit
struct Task {
  name: String
  cmds: Array[Cmd]
}

// Construction is with comma-separated fields
Task:: {
  name: "build",
  cmds: [],
  desc: None
}
```

**Key differences**:
- MoonBit uses `Array[T]` (not slice `[]T`)
- Standard library has no `List[T]` (use `Array`)
- Structure type functions need wrapper types
- Cross-package type references in structure fields **not supported**
- Structure construction with **comma**-separated fields

### 2.5. Block Style

MoonBit code is composed of **blocks** separated by `///|`:

```moonbit
///| First block - function
fn version() -> String {
  "0.1.0"
}

///|

///| Second block - structure
struct Config {
  name: String
}

///|

///| Third block - method
fn Config::get_name(self: Config) -> String {
  self.name
}
```

**Important**: Each block contains **one definition** (function, structure, method, etc.)

### 3. Cross-package Type References (Limitations)

❌ **This won't work**:
```moonbit
struct Executor {
  taskfile: Option[@taskfile/ast/Taskfile]  // Error!
}
```

✅ **Workarounds**:
1. Define types in the same package
2. Use type aliases (with limitations)
3. Flatten package structure

**Recommendation**: For now, group related types in the same package

### 4. Syntax Memo

#### Constants
```moonbit
// Use `const` for uppercase names
pub const DEBUG : String = "DEBUG"

// Use `let` for lowercase names
pub let debug = "debug"
```

#### Structure Construction
```moonbit
// All fields
Task:: {
  name: "build",
  cmds: [],
  desc: None
}

// Short hand (when variable name matches field name)
let name = "build"
Task:: { name, cmds: [], desc: None }
```

#### Pattern Matching
```moonbit
match value {
  None => ()
  Some(x) => println(x)
  _ => println("default")
}
```

#### String Concatenation
```moonbit
// Use `+` not `++`
let msg = "Hello" + " " + name
```

#### Arrays
```moonbit
// Type-annotated empty array
let arr: Array[String] = []

// Array operations
Array::map(arr, fn(x) { x + "!" })
Array::foldl(arr, init, fn(acc, x) { acc + x })
```

### 5. Reserved Words

Don't use as field or function names:
- `defer` → `defer_cmd` to use
- `method` → `method_name` to use
- `ref` → `ref_str` to use
- `use` → reserved for future use
- `mut` → for mutable fields

### 6. Standard Library

Common types and functions:
- `Array[T]` - Dynamic array
- `Map[K, V]` - Hash map
- `Option[T]` - Option value (`Some` | `None`)
- `Result[T, E]` - Error handling (`Ok` | `Err`)
- `sys/get_args()` - Command-line arguments
- `println()` / `eprintln()` - I/O

## Implementation Status (2026/03/30 2nd update)

| Component | Status | Notes |
|-----------|--------|-------|
| AST Type Definitions | ✅ Complete | Integrated into task_mbt package |
| Logger | ✅ Complete | Integrated into task_mbt package |
| Executor | ✅ **Basic Complete** | Build success with package flattening |
| CLI Parser | ✅ Basic | Argument parsing works |
| YAML Parser | ✅ Library | `moonbit-community/yaml` added |
| **YAML → AST** | ✅ **Complete** | Taskfile parser implemented |
| **CLI Demo** | ✅ **Complete** | Taskfile reading → task display → command execution (stub) |
| **E2E Tests** | ✅ **Complete** | **85 tests passed using go-task testdata** |
| **Unit Tests** | ✅ **Complete** | **`moon test`/`moon run` normal** |
| **Command Execution** | ⏳ **FFI Under Investigation** | C FFI not complete, alternative needed |
| Dependency Resolution | ❌ Not Started | Topological sort needed |
| Fingerprinting | ❌ Not Started | Complex hash processing needed |
| Parallel Execution | ❌ Not Started | Concurrency model needed |

## Test Strategy

### E2E Tests (✅ Implemented)

Use go-task test fixtures directly:

```bash
# Run 99 test cases
./scripts/test-e2e.sh
```

**Result**: 85 passed / 14 skipped / 0 failures 🎉

**Test fixture location**:
```
testdata/
├── deps/              # Dependency tests
├── env/               # Environment variable tests
├── dry/               # Dry run tests
├── checksum/          # Checksum tests
└── ... (99 cases)
```

### Unit Tests (⚠️ Under Investigation)

MoonBit test syntax is under investigation:
- `#[test]` attribute not recognized
- Alternative syntax needed

## Key Discoveries (3rd session)

### 1. MoonBit Package Structure Best Practices

**Problem**: Cross-package type references don't work
```moonbit
// ❌ This doesn't work
struct Executor {
  taskfile: Option[@taskfile/ast/Taskfile]
}
```

**Solution**: Flatten package structure
```moonbit
// ✅ Consolidate into one package
// task_mbt.mbt, types.mbt, logger.mbt, parser.mbt
// All in the same package (utenadev/task_mbt)

struct Executor {
  taskfile: Option[Taskfile]  // Directly accessible since same package
  logger: Logger
}
```

**File structure**:
```
task_mbt/
├── task_mbt.mbt      # Executor, executor logic
├── types.mbt         # Taskfile, Task, Cmd etc. type definitions
├── logger.mbt        # Logger implementation
├── parser.mbt        # YAML → Taskfile parser
└── moon.pkg.json     # import ["moonbit-community/yaml"]
```

### 2. Structure Immutability

MoonBit structure fields are **immutable by default**:
```moonbit
// ❌ This is an error
let taskfile = new_taskfile()
taskfile.version = Some(v)  // Error: field is immutable

// ✅ Create new instance
let taskfile = Taskfile:: {
  location: "",
  version: Some(v),
  ...
}
```

### 3. `for` Loop Syntax
```moonbit
// ✅ Map iteration
for entry in map {
  let (key, value) = entry
  // processing
}

// ✅ Array iteration
for item in array {
  // processing
}
```

### 4. Reserved Word `method`
`method` is a MoonBit reserved word. Don't use as field name:
```moonbit
// ⚠️ Warning appears
struct Task {
  method: Option[String]  // Warning: reserved keyword
}

// ✅ Workaround
struct Task {
  method_name: Option[String]  // OK
}
```

### 1. Gemini API Capacity Issue
- **As of March 2026, Gemini CLI frequently shows 429 errors**
- **Model-specific capacity shortage**: `gemini-3-pro-preview` especially severe
- **maxOutputTokens bug**: gmn default 65536 is out of range (max 65535)
- **OAuth client limit**: Free tier priority reduced with 3/24 change

### 2. Cross-package Type Reference (Unresolved)
- **Correct method**: `moon.pkg.json` import + `pub type` for exposure
- **But still errors in structure fields**
- **Workaround**: Flatten package structure, or use type aliases

### 3. MoonBit FFI Current State
- **`@ffi.c` attribute**: Experimental, syntax unstable
- **C types (Pointer, Int8)**: Undefined
- **string/to_c_char_pointer**: Doesn't exist
- **Alternative**: Keep as stub until needed

### 3. Project Structure
```
cmd/          # Entry points
pkg/          # Public libraries
internal/     # Internal packages
```

## Dependencies (from Go original)

Go dependencies to replace:
- `go.yaml.in/yaml/v3` → `moonbit-community/yaml` ✅ Found
- `mvdan.cc/sh/v3` → MoonBit shell integration needed
- `github.com/zeebo/xxh3` → MoonBit hash library needed
- `github.com/Masterminds/semver/v3` → MoonBit semver library needed

## Next Steps

### Near Term
1. **Fix type references** - Flatten package structure or use type aliases
2. **Add YAML parsing** - MoonBit YAML parser (complete)
3. **Basic execution test** - Run simple Taskfile

### Mid Term
4. **Shell command execution** - Integrate with system shell
5. **Variable expansion** - `{{.VAR}}` template engine
6. **Dependency resolution** - Topological sort for task dependencies

### Long Term
7. **Fingerprinting** - Incremental build file hashing
8. **Parallel execution** - Concurrent task execution
9. **Watch mode** - File system monitoring
10. **Remote Taskfiles** - HTTP/Git support

## MoonBit Resources

### Essential Documentation
- **[MoonBit for Go Programmers](https://docs.moonbitlang.com/en/latest/tutorial/for-go-programmers/index.html)**
  - Concept mapping from Go to MoonBit
  - Helpful for understanding idioms and patterns

- **[Language Fundamentals](https://docs.moonbitlang.com/en/latest/tutorial/fundamentals/index.html)**
  - Core syntax and semantics

- **`.skills/` directory** (MoonBit Agent Guide)
  - `fundamentals.mbt.md` - Basic syntax, structures, pattern matching
  - `methods.mbt.md` - Method definition and impl blocks
  - `packages.md` - Package system and imports
  - `derive.md` - Automatic derivation of Eq, Hash, JSON etc.
  - `attributes.md` - Compiler directives

These resources enable creating MoonBit code without prior experience.

### Package Registry
- **[mooncakes.io](https://mooncakes.io/)** - MoonBit package registry
  - Library search (YAML, JSON etc.)
  - Documentation often sparse; source code exploration needed

## Build Commands

```bash
# Build CLI
moon build cmd/task

# Run CLI
moon run cmd/task --help

# Run tests
moon test

# Format code
moon fmt

# Generate interface
moon info
```

## Known Issues

### Critical Blockers

1. **Cross-package Type Reference** (High severity)
   - Can't reference types from other packages in structure fields
   - Error: `Expected upper case identifier for type name, found lower case identifier`
   - Workaround: Flatten package structure, or define types locally
   - Impact: Forced architecture changes from Go original

2. **Structure Type Functions** (Medium severity)
   - Can't directly use `(String) -> Unit` as structure field function type
   - Workaround: Wrapper type or global function
   - Example: `struct Handler((String) -> Unit)` might work

3. **Block Style Parse Errors** (High severity)
   - MoonBit requires blocks separated by `///|`
   - Each block must contain one definition
   - Error: `Parse error, unexpected token '}', you may expect '.' id (uppercase start)`
   - Cause: Probably missing `///|` between definitions

### Syntax Pitfalls

4. **Reserved Words** (Low severity)
   - `defer` → `defer_cmd` to use
   - `method` → `method_name` to use
   - `ref` → `ref_str` to use
   - `use` → reserved for future use
   - `mut` → for mutable fields

5. **String Concatenation** (Low severity)
   - Use `+`, not `++`
   - `++` used for list concatenation in some contexts

6. **Array vs List** (Low severity)
   - MoonBit uses `Array[T]`, not `List[T]`
   - Empty array: type annotation `[] as Array[String]`

7. **Package Reference Syntax** (Medium severity)
   - Use `@package.function`, not `@package/function`
   - Function calls need parentheses: `@pkg.fn(arg)`, `@pkg.fn arg` is invalid

### Tool Issues

8. **Documentation Scarcity** (Medium severity)
   - mooncakes.io package documentation often empty
   - Need to explore `.mbti` interface files directly
   - GitHub source may be outdated

9. **Error Messages** (Low severity)
   - Some messages are unclear
   - "Partial type is not allowed" - structure definition
   - "Missing_priv" - internal type warning
   - "you may expect '.' id (uppercase start)" - often misleading

## Design Decisions

### Why Array not List?
MoonBit's standard library uses dynamic array `Array[T]`. `List` is unavailable.

### Why no Function Type in Logger?
MoonBit doesn't support function types directly in structure fields. Use global `println` instead.

### Why Flatten Package Structure?
To avoid the cross-package type reference problem. Re-evaluate when MoonBit adds support.

### Current Architecture Choice
**Problem**: Go's modular package structure doesn't directly map to MoonBit.

**Solution**: Flat structure from start, refactor when MoonBit improves:
- Keep AST types and helpers together
- Keep executor and types in same package
- Use internal packages only for true utilities (logger, etc.)

## Current Build Status

**Point**: First development session

**Errors**: ~70 errors, ~96 warnings
- Main cause: Cross-package type references in structure fields
- Secondary: errors/ package syntax issues

**Working Components**:
- ✅ Logger package
- ✅ AST type definitions (taskfile/ast/)
- ✅ CLI argument parsing
- ✅ YAML library integration

**Blocked Components**:
- ❌ Executor (type reference issue)
- ❌ Error type (syntax issue)
- ❌ YAML → AST conversion (API unknown)

## References

- [go-task/task v3 Source](https://github.com/go-task/task/tree/main)
- [MoonBit Documentation](https://docs.moonbitlang.com/)
- [MoonBit Core Library](https://github.com/moonbitlang/core)
- [mooncakes.io](https://mooncakes.io/)
