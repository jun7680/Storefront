import ComposableArchitecture
import Foundation

@Reducer
struct BrowserTab {
    @ObservableState
    struct State: Equatable, Identifiable {
        let id: UUID
        var browser: BrowserFeature.State

        init(id: UUID, databaseURL: URL) {
            self.id = id
            self.browser = BrowserFeature.State(databaseURL: databaseURL)
        }

        var title: String { browser.databaseURL.lastPathComponent }
        var subtitle: String { browser.databaseURL.deletingLastPathComponent().lastPathComponent }
    }

    enum Action {
        case browser(BrowserFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.browser, action: \.browser) {
            BrowserFeature()
        }
    }
}
