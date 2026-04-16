import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var currentDocumentURL: URL?
        var isFileImporterPresented: Bool = false
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case openButtonTapped
        case reloadMenuSelected
        case fileImported(Result<URL, Error>)
        case closeDocument
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
                // Phase 3에서 FileWatcher와 연결
                return .none

            case let .fileImported(.success(url)):
                state.currentDocumentURL = url
                state.isFileImporterPresented = false
                return .none

            case .fileImported(.failure):
                state.isFileImporterPresented = false
                return .none

            case .closeDocument:
                state.currentDocumentURL = nil
                return .none
            }
        }
    }
}
