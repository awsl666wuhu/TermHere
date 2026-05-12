import AppKit
import FinderSync
import os.log

final class FinderSyncController: FIFinderSync {
    private let log = OSLog(subsystem: "com.termhere.TermHere.Finder", category: "extension")

    private var pendingContext: SelectionContext?
    private var pendingActions: [Action] = []

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        os_log("TermHereFinder initialized", log: log, type: .info)
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        guard let context = SelectionContext.resolve(menuKind: menuKind) else {
            os_log("No context resolved for menuKind=%{public}d", log: log, type: .info, menuKind.rawValue)
            return NSMenu()
        }
        pendingContext = context
        os_log("Building menu, target=%{public}@", log: log, type: .info, context.targetDirectory.path)
        return MenuBuilder.build(
            for: context,
            target: self,
            selector: #selector(handleMenuClick(_:)),
            clickableActions: &pendingActions
        )
    }

    @objc private func handleMenuClick(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx >= 0, idx < pendingActions.count else {
            os_log("Click tag out of range tag=%d count=%d", log: log, type: .error, idx, pendingActions.count)
            return
        }
        guard let context = pendingContext else {
            os_log("No pending context", log: log, type: .error)
            return
        }
        let action = pendingActions[idx]
        os_log("Running action=%{public}@ target=%{public}@", log: log, type: .info, action.id, context.targetDirectory.path)
        action.run(in: context)
    }
}
