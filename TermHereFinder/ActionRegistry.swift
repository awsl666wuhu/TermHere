import Foundation

enum ActionRegistry {
    static let actions: [Action] = [
        OpenTerminalAction(),
        CopyPathAction(),
        OpenWithAction(),
        RunCommandAction(),
        NewFileAction(),
    ]
}
