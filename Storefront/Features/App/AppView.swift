import ComposableArchitecture
import SwiftUI
import UniformTypeIdentifiers

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if store.currentDocumentURL == nil {
                WelcomeView(store: store)
            } else {
                ContentUnavailableView(
                    "Phase 2에서 구현됩니다",
                    systemImage: "tray",
                    description: Text("SQLite 뷰어는 다음 단계 작업입니다.")
                )
            }
        }
        .background(Color("AppBackground"))
        .fileImporter(
            isPresented: $store.isFileImporterPresented,
            allowedContentTypes: Self.allowedContentTypes,
            onCompletion: { result in
                store.send(.fileImported(result))
            }
        )
    }

    private static let allowedContentTypes: [UTType] = [
        .database,
        UTType(filenameExtension: "sqlite") ?? .data,
        UTType(filenameExtension: "sqlite3") ?? .data,
        UTType(filenameExtension: "db") ?? .data,
        UTType(filenameExtension: "store") ?? .data
    ]
}

#Preview("Light") {
    AppView(
        store: Store(initialState: AppFeature.State()) { AppFeature() }
    )
    .frame(width: 900, height: 560)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    AppView(
        store: Store(initialState: AppFeature.State()) { AppFeature() }
    )
    .frame(width: 900, height: 560)
    .preferredColorScheme(.dark)
}
