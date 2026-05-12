import XCTest
@testable import TermHereFinder

final class TemplateSubstitutionTests: XCTestCase {
    func testSubstitutesPath() {
        let result = TemplateSubstitution.apply("cd {path}", variables: ["path": "/tmp"])
        XCTAssertEqual(result, "cd /tmp")
    }

    func testSubstitutesMultipleOccurrences() {
        let result = TemplateSubstitution.apply("{name}.{name}", variables: ["name": "x"])
        XCTAssertEqual(result, "x.x")
    }

    func testLeavesUnknownTokensIntact() {
        let result = TemplateSubstitution.apply("{path} {unknown}", variables: ["path": "/tmp"])
        XCTAssertEqual(result, "/tmp {unknown}")
    }

    func testHandlesEmptyString() {
        XCTAssertEqual(TemplateSubstitution.apply("", variables: ["path": "/tmp"]), "")
    }

    func testHandlesNoVariables() {
        XCTAssertEqual(TemplateSubstitution.apply("hello", variables: [:]), "hello")
    }
}

final class ConfigLoaderDirectoryTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("TermHereTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testLoadsAndSortsByTitle() throws {
        let cursor = #"{"title":"Cursor","bundleId":"com.todesktop.x","args":["{path}"]}"#
        let vscode = #"{"title":"Visual Studio Code","bundleId":"com.microsoft.VSCode","args":["{path}"]}"#
        try cursor.write(to: tempDir.appendingPathComponent("cursor.json"), atomically: true, encoding: .utf8)
        try vscode.write(to: tempDir.appendingPathComponent("vscode.json"), atomically: true, encoding: .utf8)

        let entries: [OpenWithEntry] = try ConfigLoader.loadAll(from: tempDir)
        XCTAssertEqual(entries.map(\.title), ["Cursor", "Visual Studio Code"])
    }

    func testReturnsEmptyForMissingDirectory() throws {
        let missing = tempDir.appendingPathComponent("missing")
        let entries: [OpenWithEntry] = try ConfigLoader.loadAll(from: missing)
        XCTAssertTrue(entries.isEmpty)
    }

    func testSkipsMalformedFiles() throws {
        try "not json".write(to: tempDir.appendingPathComponent("bad.json"), atomically: true, encoding: .utf8)
        let good = #"{"title":"Good","bundleId":"com.x","args":[]}"#
        try good.write(to: tempDir.appendingPathComponent("good.json"), atomically: true, encoding: .utf8)
        let entries: [OpenWithEntry] = try ConfigLoader.loadAll(from: tempDir)
        XCTAssertEqual(entries.map(\.title), ["Good"])
    }

    func testDecodesOpenWithEntryWithoutArgs() throws {
        let json = #"{"title":"Zed","bundleId":"dev.zed.Zed"}"#
        try json.write(to: tempDir.appendingPathComponent("zed.json"), atomically: true, encoding: .utf8)
        let entries: [OpenWithEntry] = try ConfigLoader.loadAll(from: tempDir)
        XCTAssertEqual(entries.map(\.title), ["Zed"])
        XCTAssertNil(entries.first?.args)
    }

    func testDecodesOpenWithEntryPreservesArgsIfPresent() throws {
        let json = #"{"title":"Legacy","bundleId":"com.x","args":["{path}","--flag"]}"#
        try json.write(to: tempDir.appendingPathComponent("legacy.json"), atomically: true, encoding: .utf8)
        let entries: [OpenWithEntry] = try ConfigLoader.loadAll(from: tempDir)
        XCTAssertEqual(entries.first?.args, ["{path}", "--flag"])
    }
}
