import XCTest
import FinderSync
@testable import TermHereFinder

final class RunCommandVariablesTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("RunCommandTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func makeContext(selectedItems: [URL], target: URL? = nil) -> SelectionContext {
        SelectionContext(
            targetDirectory: target ?? tempDir,
            selectedItems: selectedItems,
            menuKind: selectedItems.isEmpty ? .contextualMenuForContainer : .contextualMenuForItems
        )
    }

    func testSingleFileSelection() {
        let file = tempDir.appendingPathComponent("foo.swift")
        let vars = RunCommandSubAction.makeVariables(context: makeContext(selectedItems: [file]))
        XCTAssertEqual(vars["path"], tempDir.path)
        XCTAssertEqual(vars["filename"], "foo.swift")
        XCTAssertEqual(vars["name"], "foo")
        XCTAssertEqual(vars["selection"], "'foo.swift'")
    }

    func testMultiSelectSameDirectory() {
        let a = tempDir.appendingPathComponent("a.swift")
        let b = tempDir.appendingPathComponent("b.swift")
        let vars = RunCommandSubAction.makeVariables(context: makeContext(selectedItems: [a, b]))
        XCTAssertEqual(vars["filename"], "a.swift")
        XCTAssertEqual(vars["name"], "a")
        XCTAssertEqual(vars["selection"], "'a.swift' 'b.swift'")
    }

    func testMultiSelectAcrossSubdirectories() {
        // Common parent is tempDir; selection paths should be relative to tempDir.
        let foo = tempDir.appendingPathComponent("a/foo.swift")
        let bar = tempDir.appendingPathComponent("b/bar.swift")
        let vars = RunCommandSubAction.makeVariables(
            context: makeContext(selectedItems: [foo, bar], target: tempDir))
        XCTAssertEqual(vars["filename"], "foo.swift")
        XCTAssertEqual(vars["name"], "foo")
        XCTAssertEqual(vars["selection"], "'a/foo.swift' 'b/bar.swift'")
    }

    func testContainerRightClickHasEmptyFileVars() {
        let vars = RunCommandSubAction.makeVariables(context: makeContext(selectedItems: []))
        XCTAssertEqual(vars["path"], tempDir.path)
        XCTAssertEqual(vars["filename"], "")
        XCTAssertEqual(vars["name"], "")
        XCTAssertEqual(vars["selection"], "")
    }

    func testFilenameWithSpacesAndQuotesShellQuoted() {
        let file = tempDir.appendingPathComponent("it's a file.swift")
        let vars = RunCommandSubAction.makeVariables(context: makeContext(selectedItems: [file]))
        XCTAssertEqual(vars["filename"], "it's a file.swift")
        XCTAssertEqual(vars["selection"], "'it'\\''s a file.swift'")
    }

    func testFilenameWithoutExtensionNameEqualsFilename() {
        let file = tempDir.appendingPathComponent("README")
        let vars = RunCommandSubAction.makeVariables(context: makeContext(selectedItems: [file]))
        XCTAssertEqual(vars["filename"], "README")
        XCTAssertEqual(vars["name"], "README")
    }

    func testCommandSubstitutionEndToEnd() {
        let file = tempDir.appendingPathComponent("Foo.swift")
        let vars = RunCommandSubAction.makeVariables(context: makeContext(selectedItems: [file]))
        let rendered = TemplateSubstitution.apply(
            "claude '请审核 {filename}，重点关注 {name} 的命名'", variables: vars)
        XCTAssertEqual(rendered, "claude '请审核 Foo.swift，重点关注 Foo 的命名'")
    }
}
