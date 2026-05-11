import Foundation

enum ConfigBootstrapper {
    /// Subdirectories created under destinationRoot.
    static let subdirs = ["open-with", "run", "move-to", "new-file"]

    /// Default location for user config.
    static var defaultDestinationRoot: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("TermHere", isDirectory: true)
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
