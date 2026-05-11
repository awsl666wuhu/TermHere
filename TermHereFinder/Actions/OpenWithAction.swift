import AppKit
import os.log

struct OpenWithAction: GroupAction {
    private static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "OpenWithAction")

    let id = "open-with"
    let title = "Open With"
    var icon: NSImage? { NSImage(systemSymbolName: "arrow.up.right.square", accessibilityDescription: nil) }

    func isAvailable(in context: SelectionContext) -> Bool { true }

    func loadItems(in context: SelectionContext) -> [Action] {
        let entries: [OpenWithEntry] = (try? ConfigLoader.loadAll(from: ConfigPaths.openWithDir)) ?? []
        return entries.compactMap { entry in
            if entry.showOnlyIfInstalled ?? true {
                guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.bundleId) != nil else { return nil }
            }
            return OpenWithSubAction(entry: entry)
        }
    }
}

private struct OpenWithSubAction: Action {
    let entry: OpenWithEntry
    var id: String { "open-with:\(entry.bundleId)" }
    var title: String { entry.title }
    var icon: NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.bundleId) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    func isAvailable(in context: SelectionContext) -> Bool { true }

    func run(in context: SelectionContext) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.bundleId) else { return }
        let path = context.targetDirectory.path
        let args = entry.args.map { TemplateSubstitution.apply($0, variables: ["path": path]) }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.arguments = args
        NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
    }
}
