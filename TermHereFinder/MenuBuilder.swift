import AppKit

enum MenuBuilder {
    /// Builds the TermHere submenu. The caller passes in (and is later given back)
    /// a flat list of every clickable action, indexed by the `tag` set on each menu item.
    static func build(
        for context: SelectionContext,
        target: AnyObject,
        selector: Selector,
        clickableActions: inout [Action]
    ) -> NSMenu {
        clickableActions.removeAll()

        let outer = NSMenu(title: "TermHere")
        let submenu = NSMenu(title: "TermHere")
        let host = NSMenuItem(title: "TermHere", action: nil, keyEquivalent: "")
        host.submenu = submenu
        outer.addItem(host)

        var sawTopLevel = false
        var addedAnyGroup = false

        for action in ActionRegistry.actions where action.isAvailable(in: context) {
            if let group = action as? GroupAction {
                let items = group.loadItems(in: context)
                guard !items.isEmpty else { continue }
                if sawTopLevel && !addedAnyGroup {
                    submenu.addItem(.separator())
                }
                addedAnyGroup = true
                let sub = NSMenu(title: group.submenuTitle)
                let parent = NSMenuItem(title: group.submenuTitle, action: nil, keyEquivalent: "")
                parent.image = group.icon
                parent.submenu = sub
                submenu.addItem(parent)
                for item in items {
                    let mi = NSMenuItem(title: item.title, action: selector, keyEquivalent: "")
                    mi.target = target
                    mi.image = item.icon
                    mi.tag = clickableActions.count
                    sub.addItem(mi)
                    clickableActions.append(item)
                }
            } else {
                sawTopLevel = true
                let mi = NSMenuItem(title: action.title, action: selector, keyEquivalent: "")
                mi.target = target
                mi.image = action.icon
                mi.tag = clickableActions.count
                submenu.addItem(mi)
                clickableActions.append(action)
            }
        }

        return outer
    }
}
