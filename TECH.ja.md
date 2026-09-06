# Task MBT - 技術ノート

## プロジェクト概要

[go-task/task](https://github.com/go-task/task) の MoonBit への移植。

**go-task バージョン**: v3 (latest)
**MoonBit バージョン**: Latest stable

## アーキテクチャ比較

### Go 元の構造
```
go-task/
├── executor.go      # メインエグゼキューター
├── task.go          # タスク実行
├── setup.go         # 初期化
├── taskfile/
│   ├── reader.go    # Taskfile パース
│   ├── node.go      # ファイル/HTTP/Git ノード
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
└── cmd/task/        # CLI エントリーポイント
```

### MoonBit 移植版の構造
```
task_mbt/
├── task_mbt.mbt          # エグゼキューターコア
├── taskfile/
│   └── ast/
│       ├── task.mbt      # AST 型定義
│       └── helpers.mbt   # コンストラクタ
├── internal/
│   └── logger/
│       └── logger.mbt    # ロギング
└── cmd/task/
    └── main.mbt          # CLI
```

## 技術的な知見

### 1. パッケージシステム

**Go**: `import "path/to/package"` を使用

**MoonBit**: `moon.pkg.json` でインポートを定義、`@alias` でアクセス

```json
{
  "import": [
    "utenadev/task_mbt/internal/logger"
  ]
}
```

```moonbit
// 使い方 - スラッシュではなくドット！
@logger.info(logger, "message")      // ✅ 正
@logger/info(logger, "message")      // ❌ 誤
```

### 1.5. 関数呼び出し構文

MoonBit は**スペース区切り**の関数呼び出しで、引数はカッコ：

```moonbit
@yaml.Yaml::load_from_string(yaml_str)     // ✅ 正
@yaml.Yaml::load_from_string yaml_str      // ❌ 誤（時々動く）
@logger.new_logger(verbose, color)         // ✅ 正
```

### 2. 型システムの違い

#### Go 構造体
```go
type Task struct {
    Name string
    Cmds []*Cmd
}
```

#### MoonBit 構造体
```moonbit
struct Task {
  name: String
  cmds: Array[Cmd]
}

// 構築はフィールドをカンマ区切り
Task:: {
  name: "build",
  cmds: [],
  desc: None
}
```

**主な違い**:
- MoonBit は `Array[T]` を使用（スライス `[]T` ではない）
- 標準ライブラリに `List[T]` はない（`Array` を使用）
- 構造体の関数型にはラッパー型が必要
- 構造体フィールドでの**クロスパッケージ型参照はサポートされていない**
- 構造体構築はフィールドを**カンマ**で区切る

### 2.5. ブロックスタイル

MoonBit のコードは `///|` で区切られた**ブロック**で構成される：

```moonbit
///| 最初のブロック - 関数
fn version() -> String {
  "0.1.0"
}

///|

///| 2 番目のブロック - 構造体
struct Config {
  name: String
}

///|

///| 3 番目のブロック - メソッド
fn Config::get_name(self: Config) -> String {
  self.name
}
```

**重要**: 各ブロックには**1 つの定義**（関数、構造体、メソッドなど）を含める

### 3. クロスパッケージ型参照（制限事項）

❌ **これは動かない**:
```moonbit
struct Executor {
  taskfile: Option[@taskfile/ast/Taskfile]  // エラー！
}
```

✅ **回避策**:
1. 同じパッケージで型を定義
2. 型エイリアスを使用（制限あり）
3. パッケージ構造をフラットにする

**推奨**: 現時点では関連する型を同じパッケージにまとめる

### 4. 構文メモ

#### 定数
```moonbit
// 大文字名には `const` を使用
pub const DEBUG : String = "DEBUG"

// 小文字名には `let` を使用
pub let debug = "debug"
```

#### 構造体構築
```moonbit
// すべてのフィールド
Task:: {
  name: "build",
  cmds: [],
  desc: None
}

// ショートハンド（変数名がフィールド名と一致する場合）
let name = "build"
Task:: { name, cmds: [], desc: None }
```

#### パターンマッチ
```moonbit
match value {
  None => ()
  Some(x) => println(x)
  _ => println("default")
}
```

#### 文字列連結
```moonbit
// `++` ではなく `+` を使用
let msg = "Hello" + " " + name
```

#### 配列
```moonbit
// 型注釈付き空配列
let arr: Array[String] = []

// 配列操作
Array::map(arr, fn(x) { x + "!" })
Array::foldl(arr, init, fn(acc, x) { acc + x })
```

### 5. 予約語

フィールド名・関数名として使用しない：
- `defer` → `defer_cmd` を使用
- `method` → `method_name` を使用
- `ref` → `ref_str` を使用
- `use` → 将来の使用のために予約
- `mut` → ミュータブルフィールド用

### 6. 標準ライブラリ

一般的な型と関数：
- `Array[T]` - 動的配列
- `Map[K, V]` - ハッシュマップ
- `Option[T]` - オプション値（`Some` | `None`）
- `Result[T, E]` - エラーハンドリング（`Ok` | `Err`）
- `sys/get_args()` - コマンドライン引数
- `println()` / `eprintln()` - I/O

## 実装ステータス（2026/03/28 夜 第 3 回更新）

| コンポーネント | 状態 | 備考 |
|---------------|------|------|
| AST 型定義 | ✅ 完了 | task_mbt パッケージに統合 |
| Logger | ✅ 完了 | task_mbt パッケージに統合 |
| **Executor** | ✅ **基本完了** | パッケージフラット化でビルド成功 |
| CLI パーサー | ✅ 基本 | 引数解析動作 |
| YAML パーサー | ✅ ライブラリ | `moonbit-community/yaml` 追加済み |
| **YAML → AST** | ✅ **完了** | Taskfile パーサー実装済み |
| **CLI デモ** | ✅ **完了** | Taskfile 読み込み→タスク表示→コマンド実行（スタブ） |
| **E2E テスト** | ✅ **完了** | **go-task testdata を活用、85 件合格** |
| **コマンド実行** | ⏳ **FFI 調査中** | C FFI が未完成、代替手段が必要 |
| 依存関係解決 | ❌ 未着手 | トポロジカルソートが必要 |
| フィンガープリンティング | ❌ 未着手 | 複雑なハッシュ処理が必要 |
| 並列実行 | ❌ 未着手 | 並行モデルが必要 |

---

## テスト戦略

### E2E テスト（✅ 実装済み）

go-task のテストフィクスチャをそのまま活用：

```bash
# 99 件のテストケースを実行
./scripts/test-e2e.sh
```

**結果**: 85 件合格 / 14 件スキップ / 0 件失敗 🎉

**テストフィクスチャの場所**:
```
testdata/
├── deps/              # 依存関係テスト
├── env/               # 環境変数テスト
├── dry/               # ドライランテスト
├── checksum/          # チェックサムテスト
└── ... (99 ケース)
```

### 単体テスト（⚠️ 調査中）

MoonBit のテスト構文は調査中：
- `#[test]` 属性が認識されない
- 代替構文が必要

---

## 本日の主な発見（その 3）

### 1. MoonBit パッケージ構造のベストプラクティス

**問題**: クロスパッケージ型参照が機能しない
```moonbit
// ❌ これが動かない
struct Executor {
  taskfile: Option[@taskfile/ast/Taskfile]
}
```

**解決策**: パッケージをフラットにする
```moonbit
// ✅ 1 つのパッケージにまとめる
// task_mbt.mbt, types.mbt, logger.mbt, parser.mbt
// 全て同じパッケージ（utenadev/task_mbt）に配置

struct Executor {
  taskfile: Option[Taskfile]  // 同じパッケージなので直接参照可能
  logger: Logger
}
```

**ファイル構成**:
```
task_mbt/
├── task_mbt.mbt      # Executor, エグゼキューターロジック
├── types.mbt         # Taskfile, Task, Cmd などの型定義
├── logger.mbt        # Logger 実装
├── parser.mbt        # YAML → Taskfile パーサー
└── moon.pkg.json     # import ["moonbit-community/yaml"]
```

### 2. 構造体の不変性

MoonBit の構造体フィールドは**デフォルトで不変**：
```moonbit
// ❌ これはエラー
let taskfile = new_taskfile()
taskfile.version = Some(v)  // エラー：フィールドは不変

// ✅ 新しいインスタンスを作成
let taskfile = Taskfile:: {
  location: "",
  version: Some(v),
  ...
}
```

### 3. for ループの構文
```moonbit
// ✅ Map のイテレーション
for entry in map {
  let (key, value) = entry
  // 処理
}

// ✅ Array のイテレーション
for item in array {
  // 処理
}
```

### 4. 予約語 `method`
`method` は MoonBit の予約語。フィールド名に使用しない：
```moonbit
// ⚠️ 警告が出る
struct Task {
  method: Option[String]  // 警告：reserved keyword
}

// ✅ 回避策
struct Task {
  method_name: Option[String]  // OK
}
```

### 1. Gemini API の容量制限問題
- **2026 年 3 月現在、Gemini CLI で 429 エラーが多発**
- **モデル別容量不足**: `gemini-3-pro-preview` が特に深刻
- **maxOutputTokens バグ**: gmn のデフォルト値 65536 が範囲外（最大 65535）
- **OAuth クライアント制限**: 3/24 の変更で無料枠の優先度低下

### 2. MoonBit のクロスパッケージ型参照（未解決）
- **`import` 文**: ファイルパスではなくパッケージ名が必要
- **`using` 文**: 構文エラー
- **`@package/Type`**: 構造体フィールドでは使用不可
- **回避策**: パッケージをフラットにする、または型エイリアス

### 3. MoonBit FFI の現状
- **`@ffi.c` 属性**: 実験的機能、構文が不安定
- **C 型（Pointer, Int8）**: 未定義
- **string/to_c_char_pointer**: 存在しない
- **代替手段**: 必要になるまでスタブでOK

---

## 本日の主な発見（Gemini 相談）

### 1. シェルコマンド実行
- **C FFI がデファクト** - `system()` または `popen()` を呼び出す
- **実装例**:
  ```moonbit
  @FFI("c")
  fn system(command: CString) -> Int
  ```

### 2. クロスパッケージ型参照（未解決）
- **正しい方法**: `moon.pkg.json` で import + `pub type` で公開
- **しかし構造体フィールドでは依然エラー**
- **回避策**: パッケージをフラットにする

### 3. プロジェクト構造
```
cmd/          # エントリーポイント
pkg/          # 公開ライブラリ
internal/     # 内部パッケージ
```

## 外部ライブラリ

### YAML パーサー
- **パッケージ**: `moonbit-community/yaml@0.0.4`
- **元ネタ**: Deno std/yaml (js-yaml v3.13.1) をポート
- **追加コマンド**: `moon add moonbit-community/yaml`
- **状態**: `moon.mod.json` に追加済み、動作中

**使い方**:
```moonbit
// YAML 文字列をパース
let result = @yaml.Yaml::load_from_string(yaml_str) catch {
  e => {
    println("YAML パースエラー")
    return
  }
}

// 結果は Array[Yaml]
match result {
  [] => println("YAML ドキュメントなし")
  [yaml, ..] => {
    // yaml は Yaml 型
    // 変異形：Map, Array, String, Integer, Boolean, Null, Real, BadValue
    let dumped = @yaml.Yaml::dump(yaml)
    println(dumped)
  }
}
```

**Yaml 型の変異形**:
- `Yaml::Map(Map[String, Yaml])` - YAML オブジェクト
- `Yaml::Array(Array[Yaml])` - YAML 配列
- `Yaml::String(String)` - YAML 文字列
- `Yaml::Integer(Int64)` - YAML 整数
- `Yaml::Boolean(Bool)` - YAML ブール値
- `Yaml::Real(Double, repr~: String)` - YAML 浮動小数
- `Yaml::Null` - YAML null
- `Yaml::BadValue` - エラー値

### コマンド実行（調査中）

MoonBit でシェルコマンドを実行する標準的な方法は現時点で明確ではない。

**候補**:
1. **C FFI を使用** - `system()` 関数を呼び出す
   - 参照：[A Guide to MoonBit C-FFI](https://www.moonbitlang.com/pearls/moonbit-cffi)
   - 複雑、ネイティブコンパイルが必要

2. **process パッケージ** - `moonbitlang/core/process`
   - 存在しない可能性あり

3. **外部スクリプトを呼び出す** - 間接的な方法

**現状**: プロトタイプではスタブ実装まで


## 依存関係（Go 元）

置き換える必要がある Go 依存関係：
- `go.yaml.in/yaml/v3` → `moonbit-community/yaml` ✅ 発見
- `mvdan.cc/sh/v3` → MoonBit シェル統合が必要
- `github.com/zeebo/xxh3` → MoonBit ハッシュライブラリが必要
- `github.com/Masterminds/semver/v3` → MoonBit セムバーライブラリが必要

## 次のステップ

### 直近
1. **型参照の修正** - パッケージ構造をフラット化または型エイリアスを使用
2. **YAML パースの追加** - MoonBit 用 YAML パーサー（完了）
3. **基本実行のテスト** - シンプルな Taskfile を実行

### 中期的
4. **シェルコマンド実行** - システムシェルと統合
5. **変数展開** - `{{.VAR}}` 用テンプレートエンジン
6. **依存関係解決** - タスク依存のトポロジカルソート

### 長期的
7. **フィンガープリンティング** - 増分ビルド用ファイルハッシュ
8. **並列実行** - タスクの並行実行
9. **ウォッチモード** - ファイルシステム監視
10. **リモート Taskfiles** - HTTP/Git サポート

## MoonBit リソース

### 必須ドキュメント
- **[MoonBit for Go Programmers](https://docs.moonbitlang.com/en/latest/tutorial/for-go-programmers/index.html)**
  - Go から MoonBit への概念マッピング
  - 慣用句とパターンの理解に役立つ

- **[Language Fundamentals](https://docs.moonbitlang.com/en/latest/tutorial/fundamentals/index.html)**
  - 構文とセマンティクスの核心

- **`.skills/` ディレクトリ** (MoonBit Agent Guide)
  - `fundamentals.mbt.md` - 基本構文、構造体、パターンマッチ
  - `methods.mbt.md` - メソッド定義と impl ブロック
  - `packages.md` - パッケージシステムとインポート
  - `derive.md` - 自動導出トレイト（Eq, Hash, JSON など）
  - `attributes.md` - コンパイラディレクティブ

これらのリソースにより、事前の経験なしに MoonBit コードを作成可能。

### パッケージレジストリ
- **[mooncakes.io](https://mooncakes.io/)** - MoonBit パッケージレジストリ
  - ライブラリ検索（YAML, JSON など）
  - ドキュメントは少ないことが多い。ソースコードの探索が必要

## ビルドコマンド

```bash
# CLI をビルド
moon build cmd/task

# CLI を実行
moon run cmd/task --help

# テストを実行
moon test

# コードをフォーマット
moon fmt

# インターフェースを生成
moon info
```

## 既知の問題

### 重大なブロッカー

1. **クロスパッケージ型参照** (重要度：高)
   - 構造体フィールドで他パッケージの型を参照できない
   - エラー：`Expected upper case identifier for type name, found lower case identifier`
   - 回避策：パッケージ構造をフラット化、または型をローカルで定義
   - 影響：Go 元からのアーキテクチャ変更を余儀なくされる

2. **構造体の関数型** (重要度：中)
   - 構造体フィールドで `(String) -> Unit` を直接使用できない
   - 回避策：ラッパー型またはグローバル関数を使用
   - 例：`struct Handler((String) -> Unit)` は動作する可能性あり

3. **ブロックスタイルのパースエラー** (重要度：高)
   - MoonBit は `///|` で区切られたブロックが必要
   - 各ブロックには 1 つの定義を含める
   - エラー：`Parse error, unexpected token '}', you may expect '.' id (uppercase start)`
   - 原因：おそらく定義間に `///|` が不足

### 構文の落とし穴

4. **予約語** (重要度：低)
   - `defer` → `defer_cmd` を使用
   - `method` → `method_name` を使用
   - `ref` → `ref_str` を使用
   - `use` → 将来の使用のために予約
   - `mut` → ミュータブルフィールド用

5. **文字列連結** (重要度：低)
   - `+` を使用、`++` は使用しない
   - `++` は一部の文脈でリスト連結用

6. **Array vs List** (重要度：低)
   - MoonBit は `Array[T]` を使用、`List[T]` は使用しない
   - 空配列：型注釈に `[] as Array[String]`

7. **パッケージ参照構文** (重要度：中)
   - `@package.function` を使用、`@package/function` は使用しない
   - 関数呼び出しにはカッコが必要：`@pkg.fn(arg)`、`@pkg.fn arg` は不可

### ツールの問題

8. **ドキュメントが不足** (重要度：中)
   - mooncakes.io のパッケージドキュメントは空が多い
   - `.mbti` インターフェースファイルを直接探索する必要がある
   - GitHub のソースコードは古くなっている可能性

9. **エラーメッセージ** (重要度：低)
   - 一部のメッセージは分かりにくい
   - "Partial type is not allowed" - 構造体定義
   - "Missing_priv" - 内部型の警告
   - "you may expect '.' id (uppercase start)" - しばしば誤解を招く

## 設計上の決定

### Array ではなく List？
MoonBit の標準ライブラリは動的配列に `Array[T]` を使用。`List` は利用不可。

### Logger に関数型がないのはなぜ？
MoonBit は構造体フィールドでの関数型を直接サポートしていない。代わりにグローバル `println` を使用。

### パッケージ構造をフラットにするのはなぜ？
クロスパッケージ型参照の問題を回避するため。MoonBit がサポートを追加したら再検討。

### 現在のアーキテクチャの選択
**問題**: Go のモジュラーパッケージ構造は MoonBit に直接変換できない。

**解決策**: フラットな構造から始め、MoonBit の改善後にリファクタリング：
- AST 型とヘルパーを一緒に保つ
- エグゼキューターと型を同じパッケージに保つ
- 内部パッケージは真に独立したユーティリティ（logger など）にのみ使用

## 現在のビルドステータス

**時点**: 最初の開発セッション

**エラー**: ~70 エラー、~96 警告
- 主な原因：構造体フィールドでのクロスパッケージ型参照
- 副次的：errors/ パッケージの構文問題

**動作中のコンポーネント**:
- ✅ Logger パッケージ
- ✅ AST 型定義（taskfile/ast/）
- ✅ CLI 引数解析
- ✅ YAML ライブラリ統合

**ブロックされているコンポーネント**:
- ❌ エグゼキューター（型参照問題）
- ❌ エラー型（構文問題）
- ❌ YAML → AST 変換（API 不明）

## 参考文献

- [go-task/task v3 ソース](https://github.com/go-task/task/tree/main)
- [MoonBit ドキュメント](https://docs.moonbitlang.com/)
- [MoonBit Core Library](https://github.com/moonbitlang/core)
- [mooncakes.io](https://mooncakes.io/)
