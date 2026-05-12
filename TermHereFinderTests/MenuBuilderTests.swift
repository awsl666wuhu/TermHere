import XCTest
import AppKit
@testable import TermHereFinder

private struct StubAction: Action {
    let id: String
    var title: String { id }
    var icon: NSImage? { nil }
    var available: Bool = true
    func isAvailable(in context: SelectionContext) -> Bool { available }
    func run(in context: SelectionContext) {}
}

private struct StubGroupAction: GroupAction {
    let id: String
    var title: String { id }
    var submenuTitle: String { id }
    var icon: NSImage? { nil }
    var available: Bool = true
    let children: [Action]
    func isAvailable(in context: SelectionContext) -> Bool { available }
    func loadItems(in context: SelectionContext) -> [Action] { children }
    func run(in context: SelectionContext) {}
}

final class MenuBuilderTests: XCTestCase {
    private let context = SelectionContext(
        targetDirectory: URL(fileURLWithPath: "/tmp"),
        selectedItems: [],
        menuKind: .contextualMenuForContainer
    )

    private func itemTitles(_ menu: NSMenu) -> [String] {
        menu.items.map { $0.isSeparatorItem ? "—" : $0.title }
    }

    private func buildSubmenu(groups: [[Action]]) -> NSMenu {
        var clicks: [Action] = []
        let outer = MenuBuilder.build(
            for: context,
            target: self,
            selector: #selector(noop),
            groups: groups,
            clickableActions: &clicks
        )
        return outer.items[0].submenu!
    }

    @objc private func noop() {}

    func testSeparatorBetweenTwoNonEmptyGroups() {
        let submenu = buildSubmenu(groups: [
            [StubAction(id: "A")],
            [StubAction(id: "B")],
        ])
        XCTAssertEqual(itemTitles(submenu), ["A", "—", "B"])
    }

    func testNoSeparatorWhenSecondGroupAllUnavailable() {
        let submenu = buildSubmenu(groups: [
            [StubAction(id: "A")],
            [StubAction(id: "B", available: false)],
        ])
        XCTAssertEqual(itemTitles(submenu), ["A"])
    }

    func testEmptyGroupActionContributesNothing() {
        let submenu = buildSubmenu(groups: [
            [StubAction(id: "A")],
            [StubGroupAction(id: "EmptyG", children: [])],
            [StubAction(id: "C")],
        ])
        XCTAssertEqual(itemTitles(submenu), ["A", "—", "C"])
    }

    func testGroupActionRendersAsSubmenu() {
        let group = StubGroupAction(id: "Open With", children: [StubAction(id: "VSCode")])
        let submenu = buildSubmenu(groups: [[group]])
        XCTAssertEqual(submenu.items.count, 1)
        let parent = submenu.items[0]
        XCTAssertEqual(parent.title, "Open With")
        XCTAssertNotNil(parent.submenu)
        XCTAssertEqual(parent.submenu?.items.map(\.title), ["VSCode"])
    }
}
