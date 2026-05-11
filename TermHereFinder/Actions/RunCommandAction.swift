import AppKit

struct RunCommandAction: GroupAction {
    let id = "run"
    let title = "Run in Terminal"
    var icon: NSImage? { NSImage(systemSymbolName: "play.rectangle", accessibilityDescription: nil) }

    func isAvailable(in context: SelectionContext) -> Bool { true }

    func loadItems(in context: SelectionContext) -> [Action] {
        let entries: [RunCommandEntry] = (try? ConfigLoader.loadAll(from: ConfigPaths.runDir)) ?? []
        return entries.map { RunCommandSubAction(entry: $0) }
    }
}

private struct RunCommandSubAction: Action {
    let entry: RunCommandEntry
    var id: String { "run:\(entry.title)" }
    var title: String { entry.title }
    var icon: NSImage? { nil }
    func isAvailable(in context: SelectionContext) -> Bool { true }

    func run(in context: SelectionContext) {
        TerminalLauncher.open(at: context.targetDirectory.path, runCommand: entry.command)
    }
}
