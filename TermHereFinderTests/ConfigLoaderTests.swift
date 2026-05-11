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
