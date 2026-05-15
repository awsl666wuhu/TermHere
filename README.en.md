# TermHere

> English · [中文](README.md)

A super-lightweight macOS Finder right-click extension that makes AI-era coding more direct.

Right-click any folder in Finder and instantly get:

- **Run in Terminal ▸** — launch `claude`, `claude --dangerously-skip-permissions`, `codex`, etc. at the current path with one click
- **Open With ▸** — open the current folder in Cursor / VS Code and other AI-friendly IDEs with one click
- **Open Terminal Here** — open Terminal already `cd`-ed to the right path

No more dragging, manual `cd`, or copy-pasting paths. From "I see the code" to "AI is working on it" in a single right-click.

All commands and apps are configured via JSON files. Adding or removing presets needs no code changes and no Finder restart.

![menu](docs/screenshot.png)

## Requirements

- macOS 13 (Ventura) or later
- Full [Xcode](https://apps.apple.com/us/app/xcode/id497799835) 15+ (not just Command Line Tools)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Quick start

```bash
git clone https://github.com/awsl666wuhu/TermHere.git
cd TermHere
./scripts/install.sh
```

The script does a clean build, installs to `/Applications`, unregisters stale registrations, and restarts Finder. It's safe to re-run — every run reconciles the extension registration to the single copy at `/Applications/TermHere.app`.

If this is your first time using Xcode's command-line tools on this machine, run once:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch    # installs system components, may take a few minutes
```

You can also open `TermHere.xcodeproj` directly in Xcode and press ⌘R (good for development).

> Want to know exactly what the script does? Read [`scripts/install.sh`](scripts/install.sh) — every step is commented.

## Enable the extension (required first time)

1. Launch `TermHere.app` once (click **"Open Extension Settings…"** in the window, or open System Settings → General → Login Items & Extensions manually).
2. Find **TermHereFinder** and switch it on.
3. Close System Settings. If the menu still doesn't appear, run `killall Finder`.

## Usage

Right-click a folder / a file / blank space inside a folder → **TermHere ▸**

Top-level (high-frequency):
- **Open Terminal Here** — open a new Terminal window at the current path
- **Copy Path** — copy the path to the clipboard (one line per item on multi-select)

Submenus grouped by type:
- **Run in Terminal ▸** — run preset commands at the current path. Built-in: `claude`, `claude --dangerously-skip-permissions`, `codex`, plus three Claude starter prompts (understand the project / review this file / explain this file).
- **Open With ▸** — open with Cursor / VS Code / iTerm2 / Warp / Ghostty / Sublime, etc. (only apps actually installed on your machine show up)
- **Move To ▸** — move to a preset directory (empty by default; configure as needed)
- **New File ▸** — create a new file from a template (Markdown / Python / Shell)

| Right-click target | Available actions |
|---|---|
| Folder | All |
| File | All (Terminal/Run runs in the parent directory) |
| Blank space inside a folder | All except Move To |
| Multi-select | All (Move To moves each; Copy Path produces multiple lines; Terminal/Run uses the common parent) |

**The first click pops a dialog**: "TermHere Finder Extension wants to control Terminal" — you must click **OK** / **Allow**. This is the macOS Automation permission, which the extension needs to send AppleEvents to Terminal to open new windows.

If you accidentally click "Don't Allow", go to **System Settings → Privacy & Security → Automation** and enable Terminal under TermHere Finder Extension.

## Configuration

All configurable menu items live as JSON under `~/Library/Application Support/TermHere/`:

```
~/Library/Application Support/TermHere/
├── open-with/      # "Open with X", one .json per item
├── run/            # Run a command in Terminal, one .json per item
├── move-to/        # Move to a directory, one .json per item
└── new-file/       # File templates, one .json per item
```

On first launch the app writes a few presets; **after that, your edits and deletions are never overwritten**. To restore a preset you've removed, delete the entire `TermHere` directory and launch the app again. From the host app, click **"Reveal Config Folder"** to open this directory.

> Note: new JSON takes effect on the next right-click — **no Finder restart needed**. The extension re-reads disk every time the menu opens.

### JSON formats

`open-with/*.json` — open the current path with a specific app:
```json
{ "title": "Visual Studio Code", "bundleId": "com.microsoft.VSCode" }
```
- `title`: name shown in the menu
- `bundleId`: target app's bundle identifier (find it with `osascript -e 'id of app "Visual Studio Code"'`)
- Optional `"showOnlyIfInstalled": false` — defaults to `true`. When the app isn't installed locally, the entry is hidden by default.

`run/*.json` — `cd` to the current path in Terminal and run a command:
```json
{ "title": "Claude", "command": "claude" }
```
The command string is handed to the shell verbatim and can include arguments:
```json
{ "title": "Claude (skip permissions)", "command": "claude --dangerously-skip-permissions" }
```

The `command` field supports template variables (matching `new-file/*.json`):

- `{path}` — the current path (the command is already `cd`-ed here, so usually you don't need it)
- `{filename}` — selected file's name (with extension); empty when right-clicking blank space
- `{name}` — `{filename}` with the extension stripped; empty when right-clicking blank space
- `{selection}` — every selected item as paths relative to the current path, shell-quoted, space-joined; empty when right-clicking blank space

Custom prompt example (drop a JSON into `~/Library/Application Support/TermHere/run/`):

```json
{
  "title": "Translate this file to English",
  "command": "claude 'Please translate {filename} into English, preserving Markdown formatting.'"
}
```

Want codex or `claude --dangerously-skip-permissions` versions of the bundled prompts? Copy `claude-review-file.json` and swap `claude` for `codex` or `claude --dangerously-skip-permissions`.

`move-to/*.json` — move selected items to a target directory:
```json
{ "title": "Inbox", "destination": "~/Desktop/_inbox" }
```
`destination` supports `~` expansion; the directory is created if it doesn't exist; name collisions get ` 2`, ` 3` suffixes.

`new-file/*.json` — create a new file from a template at the current path:
```json
{ "title": "Markdown", "extension": "md", "filename": "Untitled", "content": "# {name}\n\n" }
```
Template variables:
- `{path}` — absolute path of the target directory
- `{filename}` — final filename (with extension, after collision avoidance)
- `{name}` — final filename without extension

> To add a new entry: drop a JSON file into the matching subdirectory. To remove a built-in: delete its JSON file. Effective on the next right-click.

## Project layout

```
TermHere/
├── project.yml                       # XcodeGen config — single source of truth for the project
├── Presets/                          # Bundled JSON presets, copied to the user dir on first launch
│   ├── open-with/
│   ├── run/
│   └── new-file/
├── docs/
│   ├── specs/                        # Design docs
│   └── plans/                        # Implementation plans
├── TermHere/                         # Host app (minimal SwiftUI)
│   ├── TermHereApp.swift
│   ├── ContentView.swift
│   ├── ConfigBootstrapper.swift      # Copies Presets/ to the user dir on first launch
│   └── Assets.xcassets/              # AppIcon
├── TermHereFinder/                   # Finder Sync extension
│   ├── FinderSyncController.swift    # FIFinderSync entry point
│   ├── SelectionContext.swift        # Resolves the right-click context
│   ├── MenuBuilder.swift             # Builds the TermHere submenu (incl. separator workaround)
│   ├── Action.swift                  # Plain Action protocol
│   ├── GroupAction.swift             # Action protocol with a submenu
│   ├── ConfigLoader.swift            # JSON parsing + template variables
│   ├── FilenameUtilities.swift       # Filename collision handling
│   ├── TerminalLauncher.swift        # AppleScript-based Terminal launch
│   ├── ActionRegistry.swift          # Registered action groups
│   └── Actions/
│       ├── OpenTerminalAction.swift
│       ├── CopyPathAction.swift
│       ├── OpenWithAction.swift
│       ├── RunCommandAction.swift
│       ├── MoveToAction.swift
│       └── NewFileAction.swift
└── TermHereFinderTests/              # Unit tests
```

## Adding a new action (code-level)

Just adding JSON presets? Edit `~/Library/Application Support/TermHere/` directly. To add new logic:

1. Create `MyAction.swift` under `TermHereFinder/Actions/`, conforming to `Action` (or `GroupAction` if you need a submenu).
2. Add it to the right group inside `ActionRegistry.groups`.
3. Rebuild — the new menu item shows up under `TermHere` automatically.

## Troubleshooting

| Symptom | Fix |
|---|---|
| TermHereFinder isn't listed in System Settings | Run `pluginkit -m -p com.apple.FinderSync \| grep -i term` to check registration. If missing, run `lsregister -f /Applications/TermHere.app` then `killall Finder`. |
| System Settings shows it as "File Provider" | Stale incorrect registration. Run `lsregister -u /Applications/TermHere.app` then `lsregister -f ...`. |
| **Multiple** TermHere copies show up in System Settings | Usually a copy in `DerivedData` got registered after a CLI build. Unregister them: `lsregister -u ~/Library/Developer/Xcode/DerivedData/TermHere-*/Build/Products/*/TermHere.app`, then `killall Finder`. |
| Menu shows up but clicking does nothing | `log stream --predicate 'subsystem == "com.termhere.TermHere.Finder"'` to inspect logs. Most likely AppleEvents permission was denied — go to System Settings → Privacy & Security → Automation and enable Terminal. |
| Old behavior persists after a code-and-reinstall cycle | `tccutil reset AppleEvents com.termhere.TermHere.Finder` to clear the TCC cache, then restart Finder. |
| A horizontal-line row (`─────`) appears instead of a real separator | Intentional. The Finder Sync IPC drops `NSMenuItem.separator()` markers, turning native separators into blank rows; TermHere uses a row of dashes to simulate one. |

## Uninstall

```bash
# 1) System Settings → Login Items & Extensions → turn off TermHereFinder
# 2) Remove the app and its data
rm -rf /Applications/TermHere.app
rm -rf ~/Library/Application\ Support/TermHere
tccutil reset AppleEvents com.termhere.TermHere.Finder
```

## On code signing

By default, every build command in this repo uses **ad-hoc signing** (`CODE_SIGN_IDENTITY="-"`). No Apple Developer account required; good enough for local use.

If you want to distribute to others, switch to a Developer ID signature plus notarization — otherwise Gatekeeper blocks the first launch on user machines. Set `DEVELOPMENT_TEAM` in `project.yml` and regenerate.

> ⚠️ Don't add `CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO` to `xcodebuild` — that produces a `linker-signed` weak signature that the macOS plugin system rejects. `CODE_SIGN_IDENTITY="-"` is the correct ad-hoc form.

## License

MIT
