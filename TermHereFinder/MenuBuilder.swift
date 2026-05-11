import AppKit

enum MenuBuilder {
    /// Builds the TermHere submenu. `tagsForAvailableActions` is filled with
    /// the action ids in the order they appear, indexed by menu item tag.
    static func build(
        for context: SelectionContext,
        target: AnyObject,
        selector: Selector,
        availableActionIds: inout [String]
    ) -> NSMenu {
        availableActionIds.removeAll()

        let menu = NSMenu(title: "TermHere")
        let submenu = NSMenu(title: "TermHere")
        let host = NSMenuItem(title: "TermHere", action: nil, keyEquivalent: "")
        host.submenu = submenu
        menu.addItem(host)

        for action in ActionRegistry.actions where action.isAvailable(in: context) {
            let item = NSMenuItem(title: action.title, action: selector, keyEquivalent: "")
            item.target = target
            item.image = action.icon
            item.tag = availableActionIds.count
            submenu.addItem(item)
            availableActionIds.append(action.id)
        }

        return menu
    }
}
