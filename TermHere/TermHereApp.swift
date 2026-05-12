import SwiftUI

@main
struct TermHereApp: App {
    init() {
        ConfigBootstrapper.ensureExists()
    }

    var body: some Scene {
        Window("TermHere", id: "main") {
            ContentView()
                .frame(width: 380, height: 340)
        }
        .windowResizability(.contentSize)
    }
}
