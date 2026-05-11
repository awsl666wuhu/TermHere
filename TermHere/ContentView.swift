import SwiftUI
import AppKit

struct ContentView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TermHere").font(.title2).bold()
                    Text("Open Terminal at any folder from Finder").font(.callout).foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Setup").font(.headline)
                Text("Enable the Finder extension in System Settings, then right-click any folder in Finder.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Extension Settings…") { openExtensionSettings() }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Templates").font(.headline)
                Text("Drop JSON templates into this folder to add 'New File' actions later.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Reveal Templates Folder") { revealTemplatesFolder() }
            }

            Spacer()

            HStack {
                Spacer()
                Text("v\(version)").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(20)
    }

    private func openExtensionSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!
        NSWorkspace.shared.open(url)
    }

    private func revealTemplatesFolder() {
        let url = TemplatesFolderBootstrapper.templatesURL
        TemplatesFolderBootstrapper.ensureExists()
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
