import AppKit
import os.log

struct OpenTerminalAction: Action {
    private static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "OpenTerminalAction")

    let id = "open-terminal"
    let title = "Open Terminal Here"

    var icon: NSImage? {
        NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
    }

    func run(in context: SelectionContext) {
        let path = context.targetDirectory.path
        let escaped = escapeForAppleScript(path)
        let source = """
        tell application "Terminal"
            activate
            do script "cd \(escaped) && clear"
        end tell
        """
        os_log("Running AppleScript for path=%{public}@", log: Self.log, type: .info, path)
        var errorInfo: NSDictionary?
        let script = NSAppleScript(source: source)
        _ = script?.executeAndReturnError(&errorInfo)
        if let errorInfo = errorInfo {
            os_log("AppleScript failed: %{public}@", log: Self.log, type: .error, errorInfo.description)
        } else {
            os_log("Terminal cd'd into %{public}@", log: Self.log, type: .info, path)
        }
    }

    /// Quote a POSIX path so it can be embedded inside an AppleScript string literal
    /// and then be safe as a shell argument. We rely on POSIX `printf %q` semantics
    /// by using single-quote wrapping with internal single-quote escaping.
    private func escapeForAppleScript(_ path: String) -> String {
        // Shell-quote: wrap in single quotes; escape any literal single quote as '\''
        let shellQuoted = "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        // AppleScript-quote: escape backslashes and double quotes for the string literal
        let scriptEscaped = shellQuoted
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return scriptEscaped
    }
}
