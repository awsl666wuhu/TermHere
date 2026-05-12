import XCTest
@testable import TermHereFinder

final class NewFileActionTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("TermHereNewFile-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func context() -> SelectionContext {
        SelectionContext(targetDirectory: tempDir, selectedItems: [], menuKind: .contextualMenuForContainer)
    }

    func testRunCreatesFileWithSubstitutedContent() throws {
        let entry = NewFileEntry(title: "Markdown", extension: "md", filename: "Untitled", content: "# {name}\n")
        NewFileSubAction(entry: entry).run(in: context())

        let target = tempDir.appendingPathComponent("Untitled.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.path))
        XCTAssertEqual(try String(contentsOf: target, encoding: .utf8), "# Untitled\n")
    }

    func testRunGivesSuffixOnCollision() throws {
        let entry = NewFileEntry(title: "Markdown", extension: "md", filename: "Untitled", content: "x")
        NewFileSubAction(entry: entry).run(in: context())
        NewFileSubAction(entry: entry).run(in: context())

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Untitled.md").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Untitled 2.md").path))
    }
}
