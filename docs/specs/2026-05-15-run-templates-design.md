# Run command templates + bundled prompt presets

## Context

`run/*.json` `command` is currently a literal shell string. `TerminalLauncher.open(at:runCommand:)` runs it verbatim after `cd`-ing to `targetDirectory`. Meanwhile `new-file/*.json` already supports `{path}` / `{filename}` / `{name}` template variables via `TemplateSubstitution.apply`.

This change extends the same template machinery to `run/*.json` so commands can reference the file the user clicked. With templates in place, we can ship a small set of high-quality bundled prompt presets ("Claude · 理解此项目", "Claude · 审核当前文件", "Claude · 解释当前文件") that match the AI-coding workflow the README is already pitching.

## Goals

- `run/*.json` `command` field supports four template variables: `{path}`, `{filename}`, `{name}`, `{selection}`.
- Three Claude prompt presets bundled, in Chinese, with directive phrasing.
- Existing `run/*.json` files (no template tokens) keep working unchanged.
- README documents the variables and shows an example for users to copy.

## Non-goals

- A `requiresFile: true` field to hide file-specific actions on container right-click. YAGNI; the menu title carries enough signal.
- codex / claude-yolo prompt variants bundled. README shows the JSON pattern; users copy.
- Changing `TemplateSubstitution` itself.

## Template variables

Resolved per `SelectionContext`:

| Variable      | Value                                                                          |
|---------------|--------------------------------------------------------------------------------|
| `{path}`      | `context.targetDirectory.path` (unchanged from current `cd` target)            |
| `{filename}`  | `context.selectedItems.first?.lastPathComponent` ?? `""`                       |
| `{name}`      | `{filename}` with extension stripped; `""` when filename empty                 |
| `{selection}` | All `selectedItems` as paths relative to `{path}`, shell-quoted, space-joined; `""` when no selection |

`{selection}` rationale: the command runs from `cd {path}`. Multi-select with files in different subdirectories produces e.g. `'a/foo.swift' 'b/bar.swift'` — works under any `cd {path}` because `{path}` is the common parent. Single-select produces `'foo.swift'`. Container right-click produces `""`.

Shell-quoting uses the same `'…'` + `'\''` escape as `TerminalLauncher.shellQuote` so spaces and quotes in filenames don't break the command.

## Behavior matrix

Right-click target shapes the variable values:

| Right-click | `{path}` | `{filename}` | `{name}` | `{selection}` |
|---|---|---|---|---|
| Single file `~/x/foo.swift` | `~/x` | `foo.swift` | `foo` | `'foo.swift'` |
| Single folder `~/x/proj` | `~/x/proj` | `proj` | `proj` | `'proj'` |
| Multi-select in `~/x` (`a.swift`, `b.swift`) | `~/x` | `a.swift` | `a` | `'a.swift' 'b.swift'` |
| Multi-select across (`~/x/a/foo.swift`, `~/x/b/bar.swift`) | `~/x` | `foo.swift` | `foo` | `'a/foo.swift' 'b/bar.swift'` |
| Container blank (right-click in folder background) | container path | `""` | `""` | `""` |

Container right-click of a file-only template (e.g. "审核当前文件") expands `{filename}` to `""`; the command runs as `claude '请审核 ，找出 bug ...'` — the AI will ask what to review. Acceptable degraded behavior; the menu title already implies "current file."

## Component changes

### Modify: `TermHereFinder/Actions/RunCommandAction.swift`

`RunCommandSubAction.run` builds the variables dict and applies the template before passing to `TerminalLauncher`:

```swift
func run(in context: SelectionContext) {
    let variables = RunCommandSubAction.makeVariables(context: context)
    let resolved = TemplateSubstitution.apply(entry.command, variables: variables)
    TerminalLauncher.open(at: context.targetDirectory.path, runCommand: resolved)
}

static func makeVariables(context: SelectionContext) -> [String: String] {
    let filename = context.selectedItems.first?.lastPathComponent ?? ""
    let name = filename.isEmpty ? "" : (filename as NSString).deletingPathExtension
    let selection = context.selectedItems
        .map { relativePath(of: $0, under: context.targetDirectory) }
        .map { shellQuote($0) }
        .joined(separator: " ")
    return [
        "path": context.targetDirectory.path,
        "filename": filename,
        "name": name,
        "selection": selection,
    ]
}
```

`relativePath(of:under:)` and `shellQuote(_:)` are file-private helpers (the latter mirrors `TerminalLauncher.shellQuote`; we duplicate rather than expose because both copies are 2 lines and a public-protocol breakout would be overkill).

### New bundled presets

`Presets/run/claude-understand.json`:

```json
{
  "title": "Claude · 理解此项目",
  "command": "claude '请阅读 README、各类配置或清单文件和顶层源代码，给我一份关于这个项目做什么、它的架构、关键入口的简明总结。先不要执行任何代码或修改文件。'"
}
```

`Presets/run/claude-review-file.json`:

```json
{
  "title": "Claude · 审核当前文件",
  "command": "claude '请审核 {filename}，找出 bug、设计问题、命名不清的地方。具体说明并引用行号。除非影响正确性，否则跳过吹毛求疵的小问题。'"
}
```

`Presets/run/claude-explain-file.json`:

```json
{
  "title": "Claude · 解释当前文件",
  "command": "claude '请解释 {filename} 在做什么，以及它在周围代码里的位置。假设我熟悉这门语言但是这个代码库的新人。'"
}
```

Filenames sorted alphabetically; `claude-` prefix groups them together in the menu after the existing `claude.json` / `claude-yolo.json` / `codex.json`.

### Modify: README

Add a "模板变量" subsection under `run/*.json` documenting the four variables, with one self-contained example showing how a user adds their own preset:

````markdown
`command` 字段支持模板变量（与 `new-file/*.json` 一致）：

- `{path}` —— 当前路径（命令已经 `cd` 到这里，通常用不到，留作转义需要）
- `{filename}` —— 选中文件的文件名（含扩展名）；空白处右键时为空
- `{name}` —— `{filename}` 去掉扩展名；空白处右键时为空
- `{selection}` —— 全部选中项相对当前路径的路径，已 shell 转义、空格分隔；空白处右键时为空

例子（自加 `~/Library/Application Support/TermHere/run/my-translate.json`）：

```json
{
  "title": "翻译当前文件到英文",
  "command": "claude '请把 {filename} 翻译成英文，保留 Markdown 格式。'"
}
```

更多想自加 codex / claude-yolo 版本的话，照着 `claude-review-file.json` 把 `claude` 换成 `codex` 或 `claude --dangerously-skip-permissions` 即可。
````

Also update the menu listing line:

```
- **Run in Terminal ▸** — 在当前路径运行预设命令，内置 `claude`、`claude --dangerously-skip-permissions`、`codex`，以及三个 Claude 起手 prompt（理解项目 / 审核文件 / 解释文件）
```

## Testing

### Unit tests (`TermHereFinderTests`)

New file `RunCommandActionTests.swift`:

1. **`makeVariables` with single file selected**: filename, name, selection, path all populated correctly.
2. **`makeVariables` with multi-select in same dir**: selection joins basenames with space + shell-quoting.
3. **`makeVariables` with multi-select across subdirs**: selection contains relative paths like `a/foo.swift`.
4. **`makeVariables` with container right-click (selectedItems empty)**: filename / name / selection are all `""`.
5. **`makeVariables` shell-quotes filenames containing spaces and single quotes**: `it's a file.swift` → `'it'\''s a file.swift'`.
6. **`makeVariables` filename without extension**: `name` equals `filename` (e.g. README → README).

These tests exercise the pure variable-building logic; we don't test `TerminalLauncher.open` integration (already covered by manual testing).

### Manual verification

1. Right-click `TermHereFinder/Actions/RunCommandAction.swift` → Run in Terminal → "Claude · 审核当前文件" → Terminal opens, `claude '请审核 RunCommandAction.swift...'` runs.
2. Right-click any folder → "Claude · 理解此项目" → Terminal opens, claude runs with the static prompt (no `{filename}` substitution issue).
3. Multi-select two files in same folder → "Claude · 审核当前文件" → command uses the first file's name (existing semantics for single-file actions; documented behavior).
4. Right-click folder background → "Claude · 审核当前文件" → command runs as `claude '请审核 ，...'` (empty filename); claude responds asking what to review. Verify no crash.
5. Existing `claude.json` / `codex.json` / `claude-yolo.json` continue to work unchanged.

## Upgrade path

`ConfigBootstrapper.bootstrap` is incremental — new preset files are copied on next host-app launch; existing user files (and existing user-edited `run/*.json` without the new variables) are untouched. No behavior change for existing users until they invoke the new menu items.

## Files touched

### Added
- `Presets/run/claude-understand.json`
- `Presets/run/claude-review-file.json`
- `Presets/run/claude-explain-file.json`
- `TermHereFinderTests/RunCommandActionTests.swift`

### Modified
- `TermHereFinder/Actions/RunCommandAction.swift` — template substitution + helper methods
- `README.md` — template variables doc + menu listing update

## Out of scope

- codex / claude-yolo prompt variants. README documents the pattern; user copies.
- `requiresFile: true` field. Menu titles are self-documenting.
- Multi-select semantics deeper than first-element for `{filename}` (no real use case).
- Internationalizing the prompts (this is a Chinese-first project; English README will follow as a separate PR).

## Versioning

Bump `MARKETING_VERSION` 0.2.0 → 0.2.1 in `project.yml`. User-visible feature addition (new menu items, new template variables) but no breaking change.
