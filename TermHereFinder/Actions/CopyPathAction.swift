import AppKit
import os.log

struct CopyPathAction: Action {
    private static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "CopyPathAction")

    let id = "copy-path"
    let title = "Copy Path"

    var icon: NSImage? {
        NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: nil)
    }

    func run(in context: SelectionContext) {
        let urls = context.selectedItems.isEmpty ? [context.targetDirectory] : context.selectedItems
        let joined = urls.map(\.path).joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(joined, forType: .string)
        os_log("Copied %{public}d path(s)", log: Self.log, type: .info, urls.count)
    }
}
