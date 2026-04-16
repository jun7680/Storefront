import SwiftUI

@main
struct StorefrontApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") { appState.openFileRequested = true }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button("Reload") { appState.reloadRequested = true }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
