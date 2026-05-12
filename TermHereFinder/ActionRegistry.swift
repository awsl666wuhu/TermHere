import Foundation

enum ActionRegistry {
    static let groups: [[Action]] = [
        [OpenTerminalAction(), OpenWithAction(), RunCommandAction()],
        [CopyPathAction()],
        [NewFileAction(), MoveToAction()],
    ]
}
