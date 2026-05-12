import AppKit

struct OpenTerminalAction: Action {
    let id = "open-terminal"
    let title = "Open Terminal Here"

    var icon: NSImage? {
        NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
    }

    func run(in context: SelectionContext) {
        TerminalLauncher.open(at: context.targetDirectory.path)
    }
}
