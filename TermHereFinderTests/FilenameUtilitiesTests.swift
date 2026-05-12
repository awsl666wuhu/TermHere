import XCTest
@testable import TermHereFinder

final class FilenameUtilitiesTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("TermHereTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testReturnsOriginalWhenNoCollision() {
        let url = FilenameUtilities.nonCollidingURL(in: tempDir, base: "Untitled", extension: "md")
        XCTAssertEqual(url.lastPathComponent, "Untitled.md")
    }

    func testReturnsSuffixedWhenOneCollision() throws {
        let existing = tempDir.appendingPathComponent("Untitled.md")
        try Data().write(to: existing)
        let url = FilenameUtilities.nonCollidingURL(in: tempDir, base: "Untitled", extension: "md")
        XCTAssertEqual(url.lastPathComponent, "Untitled 2.md")
    }

    func testIncrementsThroughMultipleCollisions() throws {
        for name in ["Untitled.md", "Untitled 2.md", "Untitled 3.md"] {
            try Data().write(to: tempDir.appendingPathComponent(name))
        }
        let url = FilenameUtilities.nonCollidingURL(in: tempDir, base: "Untitled", extension: "md")
        XCTAssertEqual(url.lastPathComponent, "Untitled 4.md")
    }

    func testHandlesEmptyExtension() {
        let url = FilenameUtilities.nonCollidingURL(in: tempDir, base: "README", extension: "")
        XCTAssertEqual(url.lastPathComponent, "README")
    }
}
