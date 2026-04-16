import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isFileImporterPresented: Bool = false
        var browser: BrowserFeature.State?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case openButtonTapped
        case reloadMenuSelected
        case fileImported(URL)
        case fileImportFailed(String)
        case closeDocument
        case browser(BrowserFeature.Action)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .openButtonTapped:
                state.isFileImporterPresented = true
                return .none

            case .reloadMenuSelected:
                guard state.browser != nil else { return .none }
                return .send(.browser(.refreshRequested))

            case let .fileImported(url):
                state.isFileImporterPresented = false
                state.browser = BrowserFeature.State(databaseURL: url)
                return .none

            case .fileImportFailed:
                state.isFileImporterPresented = false
                return .none

            case .closeDocument:
                state.browser = nil
                return .none

            case .browser:
                return .none
            }
        }
        .ifLet(\.browser, action: \.browser) {
            BrowserFeature()
        }
    }
}
