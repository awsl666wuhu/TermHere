import SwiftUI

@main
struct TermHereApp: App {
    init() {
        TemplatesFolderBootstrapper.ensureExists()
    }

    var body: some Scene {
        Window("TermHere", id: "main") {
            ContentView()
                .frame(width: 460, height: 320)
        }
        .windowResizability(.contentSize)
    }
}
