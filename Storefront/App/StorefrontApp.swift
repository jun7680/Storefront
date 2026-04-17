import ComposableArchitecture
import SwiftUI

@main
struct StorefrontApp: App {
    @State private var store = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
                .frame(minWidth: 900, minHeight: 560)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") { store.send(.openButtonTapped) }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button("Reload") { store.send(.reloadMenuSelected) }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
