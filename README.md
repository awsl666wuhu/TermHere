# TermHere

超轻量的 macOS Finder 右键扩展：在访达里右键任意文件夹 → **TermHere → Open Terminal Here**，立即在该路径开一个新 Terminal 窗口。

为后续扩展（新建各类文件等）预留了接口——通过 `Action` 协议 + 模板目录，新功能可零侵入加入，不必动核心代码。

![menu](docs/screenshot.png) <!-- 可选：放截图 -->

## 系统要求

- macOS 13 (Ventura) 或更高（已在 macOS 26 上测试）
- 完整版 [Xcode](https://apps.apple.com/cn/app/xcode/id497799835) 15+（不是 Command Line Tools）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`

## 快速开始

```bash
# 1) clone
git clone https://github.com/<you>/TermHere.git
cd TermHere

# 2) 如果是第一次用 Xcode 命令行，接受协议并切换路径
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch    # 装一些系统组件，可能要几分钟

# 3) 生成工程 + 构建
xcodegen generate
xcodebuild -project TermHere.xcodeproj -scheme TermHere \
  -configuration Release CODE_SIGN_IDENTITY="-" build

# 4) 安装
BUILT=$(xcodebuild -project TermHere.xcodeproj -scheme TermHere \
  -configuration Release -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/^ *BUILT_PRODUCTS_DIR/{print $2; exit}')
cp -R "$BUILT/TermHere.app" /Applications/

# 5) 让 Launch Services 立即识别（可选；不跑也行，但要等几秒）
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f /Applications/TermHere.app
killall Finder
```

也可以直接用 Xcode 打开 `TermHere.xcodeproj`，按 ⌘R 运行。

## 启用扩展（首次必做）

1. 启动一次 `TermHere.app`（启动后窗口里点 **"打开扩展设置…"**，或者手动到 系统设置 → 通用 → 登录项与扩展）
2. 找到 **TermHereFinder** 并把开关打开
3. 关闭系统设置；如菜单仍不显示，跑一次 `killall Finder`

## 使用

右键文件夹 / 文件 / 文件夹内空白处 → **TermHere ▸**

顶层（高频）：
- **Open Terminal Here** — 在当前路径开新 Terminal 窗口
- **Copy Path** — 把路径复制到剪贴板（多选则多行）

按类型嵌套的子菜单（v0.2 新增）：
- **Open With ▸** — 用 VS Code / Cursor / iTerm 等打开。检测到已安装的才会出现
- **Run in Terminal ▸** — 在当前路径运行预设命令（Claude / Codex / ...）
- **Move To ▸** — 移动到预设目录（默认为空，按需配置）
- **New File ▸** — 用模板创建新文件（Markdown / Python / Shell ...）

| 右键位置 | 适用动作 |
|---|---|
| 文件夹 | 全部 |
| 文件 | 全部（Terminal/Run 在父目录） |
| 文件夹内空白处 | 除 Move To 外全部 |
| 多选 | 全部（Move To 移动每个；Copy Path 多行；Terminal/Run 在共同父目录） |

**第一次点击会弹一个对话框**："TermHere Finder Extension 想要控制 Terminal"——必须点 **好** / **允许**。这是 macOS 的自动化权限，扩展需要它来给 Terminal 发指令开新窗口。

如果不小心点了"不允许"，到 **系统设置 → 隐私与安全性 → 自动化** 里把 TermHere Finder Extension 下的 Terminal 勾上即可。

## 配置

所有可配置菜单项以 JSON 形式存放在 `~/Library/Application Support/TermHere/`：

```
~/Library/Application Support/TermHere/
├── open-with/      # "用 X 打开"，每个 .json 一项
├── run/            # 在 Terminal 跑命令，每个 .json 一项
├── move-to/        # 移动到目录，每个 .json 一项
└── new-file/       # 文件模板，每个 .json 一项
```

首次启动会自动写入若干预设；编辑或删除都不会被覆盖。从主程序点 **"Reveal Config Folder"** 可以直接打开这个目录。

### JSON 格式

`open-with/*.json`：
```json
{ "title": "Visual Studio Code", "bundleId": "com.microsoft.VSCode", "args": ["{path}"] }
```

`run/*.json`：
```json
{ "title": "Claude", "command": "claude" }
```

`move-to/*.json`：
```json
{ "title": "Inbox", "destination": "~/Desktop/_inbox" }
```

`new-file/*.json`：
```json
{ "title": "Markdown", "extension": "md", "filename": "Untitled", "content": "# {name}\n\n" }
```

支持的模板变量：`{path}`（目标目录）、`{filename}`（含扩展名）、`{name}`（不含扩展名）。

要添加新项：写一个 JSON 文件丢进对应子目录。要删除内置项：删除对应 JSON 文件。下次右键即可生效。

## 项目结构

```
TermHere/
├── project.yml                       # XcodeGen 配置——工程的唯一真源
├── docs/
│   ├── specs/                        # 设计文档
│   └── plans/                        # 实现计划
├── TermHere/                         # 主程序（最小 SwiftUI）
├── TermHereFinder/                   # Finder Sync 扩展
│   ├── FinderSyncController.swift    # FIFinderSync 入口
│   ├── SelectionContext.swift        # 选中上下文
│   ├── MenuBuilder.swift             # 构建 TermHere 子菜单
│   ├── Action.swift                  # 普通 Action 协议
│   ├── GroupAction.swift             # 带子菜单的 Action 协议
│   ├── ConfigLoader.swift            # JSON 解析 + 模板变量
│   ├── FilenameUtilities.swift       # 文件名冲突处理
│   ├── TerminalLauncher.swift        # AppleScript 启动 Terminal
│   ├── ActionRegistry.swift          # 已注册的动作列表
│   └── Actions/
│       ├── OpenTerminalAction.swift
│       ├── CopyPathAction.swift
│       ├── OpenWithAction.swift
│       ├── RunCommandAction.swift
│       ├── MoveToAction.swift
│       └── NewFileAction.swift
├── TermHereFinderTests/              # 单元测试
└── Presets/                          # 内置 JSON 预设，首次启动写入用户目录
```

## 添加新动作

1. 在 `TermHereFinder/Actions/` 下新建 `MyAction.swift`，实现 `Action`（或 `GroupAction`）协议
2. 在 `ActionRegistry.actions` 里追加一行
3. 重新构建。新菜单项会自动出现在 `TermHere` 子菜单下

## 故障排查

| 现象 | 排查 |
|---|---|
| 系统设置里没有 TermHereFinder | `pluginkit -m -p com.apple.FinderSync \| grep term` 查是否注册；没有就 `lsregister -f /Applications/TermHere.app` 再 `killall Finder` |
| 系统设置里显示成"文件提供程序" | 旧的错误注册没清掉。`lsregister -u /Applications/TermHere.app` 再 `lsregister -f ...` |
| 系统设置里出现**多个** TermHere | 通常是命令行构建后 `DerivedData` 里的副本也被注册了。卸载它们：`lsregister -u ~/Library/Developer/Xcode/DerivedData/TermHere-*/Build/Products/*/TermHere.app`，再 `killall Finder` |
| 右键看到菜单但点击无反应 | `log stream --predicate 'subsystem == "com.termhere.TermHere.Finder"'` 看日志；多半是 AppleEvents 权限被拒，到 系统设置 → 隐私与安全性 → 自动化 里勾上 Terminal |
| 改了代码重装后还是旧行为 | `tccutil reset AppleEvents com.termhere.TermHere.Finder` 清 TCC 缓存，再重启 Finder |

## 卸载

```bash
# 1) 系统设置 → 登录项与扩展 → 关掉 TermHereFinder
# 2) 删除 app 和数据
rm -rf /Applications/TermHere.app
rm -rf ~/Library/Application\ Support/TermHere
tccutil reset AppleEvents com.termhere.TermHere.Finder
```

## 关于代码签名

仓库里所有构建命令默认使用 **ad-hoc 签名**（`CODE_SIGN_IDENTITY="-"`），无需 Apple 开发者账号，本机自用够用。

如果你要分发给别人，建议改用 Developer ID 签名 + 公证（notarization），否则用户首次打开会被 Gatekeeper 拦截。修改 `project.yml` 里的 `DEVELOPMENT_TEAM` 字段并重新生成工程即可。

> ⚠️ 不要在 `xcodebuild` 命令里加 `CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`——会让链接器输出 `linker-signed` 弱签名，macOS 的插件系统不认。`CODE_SIGN_IDENTITY="-"` 才是正确的 ad-hoc 方式。

## 许可

MIT
