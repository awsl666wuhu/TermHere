import XCTest
@testable import TermHereFinder

final class ConfigBootstrapperTests: XCTestCase {
    private var sourceDir: URL!
    private var destDir: URL!

    override func setUpWithError() throws {
        let base = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("BootstrapTests-\(UUID().uuidString)", isDirectory: true)
        sourceDir = base.appendingPathComponent("source", isDirectory: true)
        destDir = base.appendingPathComponent("dest", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: sourceDir.deletingLastPathComponent())
    }

    private func writeSource(_ relative: String, _ contents: String) throws {
        let url = sourceDir.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    func testCreatesAllFourSubdirs() throws {
        try ConfigBootstrapper.bootstrap(presetsRoot: sourceDir, destinationRoot: destDir)
        for dir in ["open-with", "run", "move-to", "new-file"] {
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: destDir.appendingPathComponent(dir).path, isDirectory: &isDir)
            XCTAssertTrue(exists && isDir.boolValue, "Expected \(dir) to be a directory")
        }
    }

    func testCopiesPresets() throws {
        try writeSource("open-with/vscode.json", #"{"x":1}"#)
        try ConfigBootstrapper.bootstrap(presetsRoot: sourceDir, destinationRoot: destDir)
        let copied = destDir.appendingPathComponent("open-with/vscode.json")
        XCTAssertEqual(try String(contentsOf: copied), #"{"x":1}"#)
    }

    func testDoesNotOverwriteExistingUserFile() throws {
        try writeSource("open-with/vscode.json", "preset")
        try FileManager.default.createDirectory(at: destDir.appendingPathComponent("open-with"), withIntermediateDirectories: true)
        try "user-edited".write(to: destDir.appendingPathComponent("open-with/vscode.json"), atomically: true, encoding: .utf8)

        try ConfigBootstrapper.bootstrap(presetsRoot: sourceDir, destinationRoot: destDir)
        XCTAssertEqual(try String(contentsOf: destDir.appendingPathComponent("open-with/vscode.json")), "user-edited")
    }

    func testIdempotent() throws {
        try writeSource("run/claude.json", "preset-v1")
        try ConfigBootstrapper.bootstrap(presetsRoot: sourceDir, destinationRoot: destDir)
        try ConfigBootstrapper.bootstrap(presetsRoot: sourceDir, destinationRoot: destDir)
        XCTAssertEqual(try String(contentsOf: destDir.appendingPathComponent("run/claude.json")), "preset-v1")
    }
}
