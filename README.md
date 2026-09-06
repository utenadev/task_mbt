# task_mbt - MoonBit Task Runner

A MoonBit port of go-task/task

## Overview

task_mbt is a task runner implemented in MoonBit, ported from go-task/task. It reads YAML-format Taskfiles and executes defined tasks.

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/utenadev/task_mbt.git
cd task_mbt

# Build
moon build cmd/cli --target native
```

## Usage

### Demo Execution

```bash
moon run cmd/cli
```

### Output Example

```
🌙 task_mbt - Command Execution Demo

📋 Running tasks...

🔷 Task: hello
   Say hello
   ▶️  Executing: echo Hello from task_mbt!
   ✅ Done! (stub)

🔷 Task: build
   Build the project
   ▶️  Executing: echo Building...
   ✅ Done! (stub)

🎉 All tasks completed!
```

## Project Structure

```
task_mbt/
├── task_mbt.mbt      # Executor core
├── types.mbt         # Type definitions (Taskfile, Task, Cmd etc.)
├── logger.mbt        # Logging
├── parser.mbt        # YAML parser
├── cmd/cli/          # CLI demo
├── taskfile/ast/     # AST type definitions (in development)
├── internal/logger/  # Logging package (in development)
└── TECH.md           # Technical notes
```

## Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| YAML Parsing | ✅ Complete | Using moonbit-community/yaml |
| Taskfile Loading | ✅ Complete | |
| Task Display | ✅ Complete | |
| **Unit Tests** | ✅ **Pass** | `moon test`/`moon run` normal |
| Command Execution | ⏳ FFI Under Investigation | C FFI not complete |
| Dependency Resolution | ❌ Not Started | Topological sort needed |
| Parallel Execution | ❌ Not Started | Concurrency model needed |

## Tech Stack

- **Language**: MoonBit
- **YAML Parser**: moonbit-community/yaml
- **Targets**: WebAssembly (wasm-gc), Native

## Development

### Build

```bash
moon build .
moon build cmd/cli
```

### Test

```bash
moon test
```

### Format

```bash
moon fmt
```

## Known Issues

1. **Shell Command Execution**: MoonBit FFI not complete, command execution is stub implementation.
2. **Cross-package Type Reference**: Due to MoonBit limitations, packages are flattened.

## References

- [go-task/task](https://github.com/go-task/task) - Original Go implementation
- [MoonBit Documentation](https://docs.moonbitlang.com/)
- [MoonBit for Go Programmers](https://docs.moonbitlang.com/en/latest/tutorial/for-go-programmers/index.html)

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributions

Issues and Pull Requests are welcome!
