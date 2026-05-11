import AppKit
import FinderSync
import os.log

struct MoveToAction: GroupAction {
    private static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "MoveToAction")

    let id = "move-to"
    let title = "Move To"
    var icon: NSImage? { NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: nil) }

    func isAvailable(in context: SelectionContext) -> Bool {
        !context.selectedItems.isEmpty && context.menuKind != .contextualMenuForContainer
    }

    func loadItems(in context: SelectionContext) -> [Action] {
        let entries: [MoveToEntry] = (try? ConfigLoader.loadAll(from: ConfigPaths.moveToDir)) ?? []
        return entries.map { MoveToSubAction(entry: $0) }
    }
}

private struct MoveToSubAction: Action {
    let entry: MoveToEntry
    var id: String { "move-to:\(entry.title)" }
    var title: String { entry.title }
    var icon: NSImage? { nil }
    func isAvailable(in context: SelectionContext) -> Bool { !context.selectedItems.isEmpty }

    func run(in context: SelectionContext) {
        let expanded = (entry.destination as NSString).expandingTildeInPath
        let destDir = URL(fileURLWithPath: expanded, isDirectory: true)
        let fm = FileManager.default
        try? fm.createDirectory(at: destDir, withIntermediateDirectories: true)

        let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "MoveToAction")
        for source in context.selectedItems {
            let base = (source.lastPathComponent as NSString).deletingPathExtension
            let ext = source.pathExtension
            let target = FilenameUtilities.nonCollidingURL(in: destDir, base: base, extension: ext)
            do {
                try fm.moveItem(at: source, to: target)
            } catch {
                os_log("Move failed %{public}@ → %{public}@: %{public}@",
                       log: log, type: .error, source.path, target.path, String(describing: error))
            }
        }
    }
}
