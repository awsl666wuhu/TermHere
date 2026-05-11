import AppKit

protocol Action {
    var id: String { get }
    var title: String { get }
    var icon: NSImage? { get }
    func isAvailable(in context: SelectionContext) -> Bool
    func run(in context: SelectionContext)
}

extension Action {
    var icon: NSImage? { nil }
    func isAvailable(in context: SelectionContext) -> Bool { true }
}
