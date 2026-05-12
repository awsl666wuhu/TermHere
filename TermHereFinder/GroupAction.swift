import Foundation

/// An action that contributes a submenu under TermHere, e.g. `Open With ▸`.
/// Sub-items are produced lazily each time the menu is built.
protocol GroupAction: Action {
    /// Title of the submenu shown under TermHere. Defaults to `title`.
    var submenuTitle: String { get }
    /// Live list of sub-actions, computed each menu open.
    func loadItems(in context: SelectionContext) -> [Action]
}

extension GroupAction {
    var submenuTitle: String { title }
    /// Default no-op; GroupActions are never invoked directly.
    func run(in context: SelectionContext) {}
}
