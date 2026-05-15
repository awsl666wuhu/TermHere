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

struct RunCommandSubAction: Action {
    let entry: RunCommandEntry
    var id: String { "run:\(entry.title)" }
    var title: String { entry.title }
    var icon: NSImage? { nil }
    func isAvailable(in context: SelectionContext) -> Bool { true }

    func run(in context: SelectionContext) {
        let variables = Self.makeVariables(context: context)
        let resolved = TemplateSubstitution.apply(entry.command, variables: variables)
        TerminalLauncher.open(at: context.targetDirectory.path, runCommand: resolved)
    }

    /// Builds template variables for the run command. See spec
    /// `docs/specs/2026-05-15-run-templates-design.md` for the contract.
    static func makeVariables(context: SelectionContext) -> [String: String] {
        let filename = context.selectedItems.first?.lastPathComponent ?? ""
        let name = filename.isEmpty ? "" : (filename as NSString).deletingPathExtension
        let selection = context.selectedItems
            .map { Self.relativePath(of: $0, under: context.targetDirectory) }
            .map(Self.shellQuote)
            .joined(separator: " ")
        return [
            "path": context.targetDirectory.path,
            "filename": filename,
            "name": name,
            "selection": selection,
        ]
    }

    /// Returns `url`'s path expressed relative to `base`.
    /// Falls back to `url.lastPathComponent` if `url` is not under `base`
    /// (shouldn't happen in practice — `SelectionContext` derives target as common parent).
    private static func relativePath(of url: URL, under base: URL) -> String {
        let basePath = base.path.hasSuffix("/") ? base.path : base.path + "/"
        let urlPath = url.path
        if urlPath.hasPrefix(basePath) {
            return String(urlPath.dropFirst(basePath.count))
        }
        return url.lastPathComponent
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
