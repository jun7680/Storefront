import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if let browserStore = store.scope(state: \.browser, action: \.browser) {
                BrowserView(store: browserStore)
            } else {
                WelcomeView(store: store)
            }
        }
        .background(Color("AppBackground"))
        .fileImporter(
            isPresented: $store.isFileImporterPresented,
            allowedContentTypes: Self.allowedContentTypes
        ) { result in
            switch result {
            case let .success(url):
                store.send(.fileImported(url))
            case let .failure(error):
                store.send(.fileImportFailed(error.localizedDescription))
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.simulatorPicker != nil },
                set: { new in
                    if !new { store.send(.simulatorPicker(.dismissTapped)) }
                }
            )
        ) {
            if let pickerStore = store.scope(state: \.simulatorPicker, action: \.simulatorPicker) {
                SimulatorPickerView(store: pickerStore)
            }
        }
    }

    private static let allowedContentTypes: [UTType] = {
        var types: [UTType] = [.database]
        for ext in ["sqlite", "sqlite3", "db", "store"] {
            if let type = UTType(filenameExtension: ext) {
                types.append(type)
            }
        }
        return types
    }()
}

#Preview("Welcome — Light") {
    AppView(
        store: Store(initialState: AppFeature.State()) { AppFeature() }
    )
    .frame(width: 900, height: 560)
    .preferredColorScheme(.light)
}
