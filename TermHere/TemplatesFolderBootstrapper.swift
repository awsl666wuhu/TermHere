import Foundation

enum TemplatesFolderBootstrapper {
    static var templatesURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("TermHere/Templates", isDirectory: true)
    }

    static func ensureExists() {
        try? FileManager.default.createDirectory(at: templatesURL, withIntermediateDirectories: true)
    }
}
