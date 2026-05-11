import AppKit
import os.log

struct NewFileAction: GroupAction {
    private static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "NewFileAction")

    let id = "new-file"
    let title = "New File"
    var icon: NSImage? { NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil) }

    func isAvailable(in context: SelectionContext) -> Bool {
        true
    }

    func loadItems(in context: SelectionContext) -> [Action] {
        let dir = ConfigPaths.newFileDir
        let entries: [NewFileEntry] = (try? ConfigLoader.loadAll(from: dir)) ?? []
        return entries.map { NewFileSubAction(entry: $0) }
    }
}

private struct NewFileSubAction: Action {
    let entry: NewFileEntry
    var id: String { "new-file:\(entry.title)" }
    var title: String { entry.title }
    var icon: NSImage? { nil }
    func isAvailable(in context: SelectionContext) -> Bool { true }

    func run(in context: SelectionContext) {
        let target = FilenameUtilities.nonCollidingURL(
            in: context.targetDirectory,
            base: entry.filename,
            extension: entry.`extension`
        )
        let filenameWithExt = target.lastPathComponent
        let nameOnly = (filenameWithExt as NSString).deletingPathExtension
        let body = TemplateSubstitution.apply(entry.content, variables: [
            "filename": filenameWithExt,
            "name": nameOnly,
            "path": context.targetDirectory.path,
        ])
        try? body.data(using: .utf8)?.write(to: target)
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }
}

/// Centralizes config-folder paths so renames stay in one place.
enum ConfigPaths {
    static var root: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("TermHere", isDirectory: true)
    }
    static var openWithDir: URL { root.appendingPathComponent("open-with", isDirectory: true) }
    static var runDir: URL { root.appendingPathComponent("run", isDirectory: true) }
    static var moveToDir: URL { root.appendingPathComponent("move-to", isDirectory: true) }
    static var newFileDir: URL { root.appendingPathComponent("new-file", isDirectory: true) }
}
