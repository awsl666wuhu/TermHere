import Foundation
import os.log

enum TerminalLauncher {
    private static let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "TerminalLauncher")

    /// Opens a new Terminal window at `path` and optionally runs `command`.
    static func open(at path: String, runCommand command: String? = nil) {
        let cdEscaped = shellQuote(path)
        let combined: String
        if let command, !command.isEmpty {
            combined = "cd \(cdEscaped) && clear && \(command)"
        } else {
            combined = "cd \(cdEscaped) && clear"
        }
        let scriptEscaped = combined
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = """
        tell application "Terminal"
            activate
            do script "\(scriptEscaped)"
        end tell
        """
        var errorInfo: NSDictionary?
        _ = NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)
        if let errorInfo {
            os_log("AppleScript failed: %{public}@", log: log, type: .error, errorInfo.description)
        }
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
