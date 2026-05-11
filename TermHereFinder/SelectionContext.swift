import Foundation
import FinderSync

struct SelectionContext {
    let targetDirectory: URL
    let selectedItems: [URL]
    let menuKind: FIMenuKind

    static func resolve(menuKind: FIMenuKind) -> SelectionContext? {
        let sync = FIFinderSyncController.default()
        let selected = sync.selectedItemURLs() ?? []

        switch menuKind {
        case .contextualMenuForItems:
            guard let target = resolveTarget(from: selected) else { return nil }
            return SelectionContext(targetDirectory: target, selectedItems: selected, menuKind: menuKind)

        case .contextualMenuForContainer:
            guard let container = sync.targetedURL() else { return nil }
            return SelectionContext(targetDirectory: container, selectedItems: [], menuKind: menuKind)

        case .contextualMenuForSidebar:
            guard let container = sync.targetedURL() else { return nil }
            return SelectionContext(targetDirectory: container, selectedItems: selected, menuKind: menuKind)

        @unknown default:
            return nil
        }
    }

    private static func resolveTarget(from items: [URL]) -> URL? {
        guard let first = items.first else { return nil }
        if items.count == 1 {
            return isDirectory(first) ? first : first.deletingLastPathComponent()
        }
        return commonParent(of: items) ?? first.deletingLastPathComponent()
    }

    private static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    private static func commonParent(of urls: [URL]) -> URL? {
        guard let first = urls.first else { return nil }
        var components = first.deletingLastPathComponent().pathComponents
        for url in urls.dropFirst() {
            let parentComponents = url.deletingLastPathComponent().pathComponents
            var shared: [String] = []
            for (a, b) in zip(components, parentComponents) where a == b {
                shared.append(a)
            }
            components = shared
            if components.isEmpty { return nil }
        }
        let path = components.joined(separator: "/").replacingOccurrences(of: "//", with: "/")
        return URL(fileURLWithPath: path.isEmpty ? "/" : path)
    }
}
