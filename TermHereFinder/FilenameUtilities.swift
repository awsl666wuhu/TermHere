import Foundation

enum FilenameUtilities {
    /// Returns a URL in `directory` whose filename doesn't already exist.
    /// Tries `<base>.<ext>`, `<base> 2.<ext>`, `<base> 3.<ext>`, ...
    static func nonCollidingURL(in directory: URL, base: String, extension ext: String) -> URL {
        let fm = FileManager.default
        let suffix = ext.isEmpty ? "" : ".\(ext)"
        var candidate = directory.appendingPathComponent("\(base)\(suffix)")
        var counter = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(base) \(counter)\(suffix)")
            counter += 1
        }
        return candidate
    }
}
