import AppKit
import os.log

struct NewFileAction: GroupAction {
    fileprivate static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "NewFileAction")

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

struct NewFileSubAction: Action {
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

        guard let data = body.data(using: .utf8) else {
            os_log("New File: could not encode body as UTF-8 for %{public}@",
                   log: NewFileAction.log, type: .error, entry.title)
            return
        }

        let scoped = context.targetDirectory.startAccessingSecurityScopedResource()
        defer { if scoped { context.targetDirectory.stopAccessingSecurityScopedResource() } }

        do {
            try data.write(to: target, options: .atomic)
        } catch {
            os_log("New File: write failed at %{public}@: %{public}@",
                   log: NewFileAction.log, type: .error, target.path, String(describing: error))
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([target])
    }
}

/// Centralizes config-folder paths so renames stay in one place.
/// Resolves to the real user home (not the per-process sandbox container) so the
/// host app and the Finder extension share the same directory. Access is granted
/// by the `com.apple.security.temporary-exception.files.home-relative-path.read-write`
/// entitlement on both targets.
enum ConfigPaths {
    static var root: URL {
        SandboxBypass.realUserHome
            .appendingPathComponent("Library/Application Support/TermHere", isDirectory: true)
    }
    static var openWithDir: URL { root.appendingPathComponent("open-with", isDirectory: true) }
    static var runDir: URL { root.appendingPathComponent("run", isDirectory: true) }
    static var moveToDir: URL { root.appendingPathComponent("move-to", isDirectory: true) }
    static var newFileDir: URL { root.appendingPathComponent("new-file", isDirectory: true) }
}

/// Resolves the user's real home directory bypassing sandbox redirection.
/// `NSHomeDirectory()` and `NSHomeDirectoryForUser(NSUserName())` both return the
/// per-process container inside a sandboxed app. `getpwuid_r` reads from the system
/// user database directly and is not redirected.
enum SandboxBypass {
    static var realUserHome: URL {
        var pwd = passwd()
        var result: UnsafeMutablePointer<passwd>? = nil
        let bufSize = sysconf(_SC_GETPW_R_SIZE_MAX)
        let bufLen = bufSize > 0 ? bufSize : 16384
        let buf = UnsafeMutablePointer<CChar>.allocate(capacity: bufLen)
        defer { buf.deallocate() }
        let uid = getuid()
        if getpwuid_r(uid, &pwd, buf, bufLen, &result) == 0, let result, let dir = result.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir))
        }
        return URL(fileURLWithPath: NSHomeDirectory())
    }
}
