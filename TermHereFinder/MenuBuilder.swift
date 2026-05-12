import AppKit

enum MenuBuilder {
    /// Marker title used for our pseudo-separator rows. Finder Sync extension menus
    /// drop the `isSeparatorItem` flag during cross-process serialization so a real
    /// `NSMenuItem.separator()` renders as a blank gap; instead we emit a disabled
    /// row whose title is a run of box-drawing characters that visually reads as a
    /// dividing line.
    static let separatorTitle = String(repeating: "─", count: 12)

    /// Builds a Finder-compatible pseudo-separator row.
    static func makePseudoSeparator() -> NSMenuItem {
        let item = NSMenuItem(title: separatorTitle, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    /// Builds the TermHere submenu from a list of semantic groups. A separator is
    /// inserted between two adjacent non-empty groups. An "empty" group is one
    /// that contributes zero menu items (all actions unavailable, or all
    /// GroupActions returning empty `loadItems`).
    static func build(
        for context: SelectionContext,
        target: AnyObject,
        selector: Selector,
        groups: [[Action]],
        clickableActions: inout [Action]
    ) -> NSMenu {
        clickableActions.removeAll()

        let outer = NSMenu(title: "TermHere")
        let submenu = NSMenu(title: "TermHere")
        let host = NSMenuItem(title: "TermHere", action: nil, keyEquivalent: "")
        host.submenu = submenu
        outer.addItem(host)

        var emittedAnyGroup = false
        for group in groups {
            let itemsBefore = submenu.items.count
            emit(group: group, into: submenu, context: context, target: target, selector: selector, clickableActions: &clickableActions)
            guard submenu.items.count > itemsBefore else { continue }
            if emittedAnyGroup {
                submenu.insertItem(makePseudoSeparator(), at: itemsBefore)
            }
            emittedAnyGroup = true
        }

        return outer
    }

    /// Old call site shim — kept so FinderSyncController doesn't need to change.
    static func build(
        for context: SelectionContext,
        target: AnyObject,
        selector: Selector,
        clickableActions: inout [Action]
    ) -> NSMenu {
        return build(
            for: context,
            target: target,
            selector: selector,
            groups: ActionRegistry.groups,
            clickableActions: &clickableActions
        )
    }

    private static func emit(
        group: [Action],
        into submenu: NSMenu,
        context: SelectionContext,
        target: AnyObject,
        selector: Selector,
        clickableActions: inout [Action]
    ) {
        for action in group where action.isAvailable(in: context) {
            if let groupAction = action as? GroupAction {
                let items = groupAction.loadItems(in: context)
                guard !items.isEmpty else { continue }
                let sub = NSMenu(title: groupAction.submenuTitle)
                let parent = NSMenuItem(title: groupAction.submenuTitle, action: nil, keyEquivalent: "")
                parent.image = groupAction.icon
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
                let mi = NSMenuItem(title: action.title, action: selector, keyEquivalent: "")
                mi.target = target
                mi.image = action.icon
                mi.tag = clickableActions.count
                submenu.addItem(mi)
                clickableActions.append(action)
            }
        }
    }
}
