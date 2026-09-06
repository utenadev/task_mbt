# task_mbt - MoonBit 版 Task Runner

Go で実装された [go-task/task](https://github.com/go-task/task) を MoonBit に移植したプロジェクトです。

## 概要

task_mbt は、Make のようなタスクランナーを MoonBit で再実装したものです。YAML 形式の Taskfile を読み込み、定義されたタスクを実行します。

**注意**: 現在開発中のプロジェクトです。機能は限定的です。

## インストール

### ソースからビルド

```bash
# リポジトリのクローン
git clone https://github.com/utenadev/task_mbt.git
cd task_mbt

# ビルド
moon build cmd/cli --target native

# バイナリは _build/native/debug/build/cmd/cli/cli.exe
```

## 使い方

### デモ実行

```bash
moon run cmd/cli
```

### 出力例

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

## プロジェクト構造

```
task_mbt/
├── task_mbt.mbt      # Executor コア
├── types.mbt         # 型定義（Taskfile, Task, Cmd など）
├── logger.mbt        # ロギング
├── parser.mbt        # YAML パーサー
├── cmd/cli/          # CLI デモ
├── taskfile/ast/     # AST 型定義（開発中）
├── internal/logger/  # ロギングパッケージ（開発中）
└── TECH.md           # 技術ノート
```

## 実装状況

| 機能 | 状態 | 備考 |
|------|------|------|
| YAML パース | ✅ 完了 | moonbit-community/yaml 使用 |
| Taskfile 読み込み | ✅ 完了 | |
| タスク表示 | ✅ 完了 | |
| コマンド実行 | ⏳ 調査中 | C FFI が必要 |
| 依存関係解決 | ❌ 未着手 | |
| 並列実行 | ❌ 未着手 | |

## 技術スタック

- **言語**: MoonBit
- **YAML パーサー**: moonbit-community/yaml
- **ターゲット**: WebAssembly (wasm-gc), Native

## 開発

### ビルド

```bash
moon build .
moon build cmd/cli
```

### テスト

```bash
moon test
```

### フォーマット

```bash
moon fmt
```

## 既知の問題

1. **シェルコマンド実行**: MoonBit の FFI が未完成のため、コマンド実行はスタブ実装です。
2. **クロスパッケージ型参照**: MoonBit の制限により、パッケージをフラットにしています。

## 参考文献

- [go-task/task](https://github.com/go-task/task) - 元となった Go 実装
- [MoonBit Documentation](https://docs.moonbitlang.com/)
- [MoonBit for Go Programmers](https://docs.moonbitlang.com/en/latest/tutorial/for-go-programmers/index.html)

## ライセンス

MIT License - [LICENSE](LICENSE) を参照してください。

## 貢献

Issue や Pull Request を歓迎します！
