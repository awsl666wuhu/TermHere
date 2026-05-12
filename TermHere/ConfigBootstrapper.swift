import Foundation

enum ConfigBootstrapper {
    /// Subdirectories created under destinationRoot.
    static let subdirs = ["open-with", "run", "move-to", "new-file"]

    /// Default location for user config: real user home (not the sandbox container)
    /// so the Finder extension reads the same directory the host app writes to.
    /// Access is granted by the `temporary-exception.files.home-relative-path.read-write`
    /// entitlement on both targets.
    static var defaultDestinationRoot: URL {
        realUserHome().appendingPathComponent("Library/Application Support/TermHere", isDirectory: true)
    }

    private static func realUserHome() -> URL {
        var pwd = passwd()
        var result: UnsafeMutablePointer<passwd>? = nil
        let bufSize = sysconf(_SC_GETPW_R_SIZE_MAX)
        let bufLen = bufSize > 0 ? bufSize : 16384
        let buf = UnsafeMutablePointer<CChar>.allocate(capacity: bufLen)
        defer { buf.deallocate() }
        if getpwuid_r(getuid(), &pwd, buf, bufLen, &result) == 0, let result, let dir = result.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir))
        }
        return URL(fileURLWithPath: NSHomeDirectory())
    }

    /// Default presets location inside the host app bundle.
    static var defaultPresetsRoot: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("Presets", isDirectory: true)
    }

    /// Convenience: bootstrap using defaults (host-app launch path).
    static func ensureExists() {
        guard let presets = defaultPresetsRoot else {
            try? FileManager.default.createDirectory(at: defaultDestinationRoot, withIntermediateDirectories: true)
            for sub in subdirs {
                try? FileManager.default.createDirectory(at: defaultDestinationRoot.appendingPathComponent(sub), withIntermediateDirectories: true)
            }
            return
        }
        try? bootstrap(presetsRoot: presets, destinationRoot: defaultDestinationRoot)
    }

    /// Pure logic: creates subdirs, copies any preset file whose destination doesn't already exist.
    static func bootstrap(presetsRoot: URL, destinationRoot: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

        for sub in subdirs {
            let destSub = destinationRoot.appendingPathComponent(sub, isDirectory: true)
            try fm.createDirectory(at: destSub, withIntermediateDirectories: true)

            let srcSub = presetsRoot.appendingPathComponent(sub, isDirectory: true)
            guard fm.fileExists(atPath: srcSub.path) else { continue }

            let presetFiles = (try? fm.contentsOfDirectory(at: srcSub, includingPropertiesForKeys: nil)) ?? []
            for src in presetFiles where src.pathExtension == "json" {
                let dest = destSub.appendingPathComponent(src.lastPathComponent)
                if !fm.fileExists(atPath: dest.path) {
                    try fm.copyItem(at: src, to: dest)
                }
            }
        }
    }
}
