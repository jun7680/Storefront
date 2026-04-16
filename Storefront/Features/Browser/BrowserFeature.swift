import ComposableArchitecture
import Foundation

@Reducer
struct BrowserFeature {
    @ObservableState
    struct State: Equatable {
        let databaseURL: URL
        var tables: [TableInfo] = []
        var selectedTableID: TableInfo.ID?
        var isLoading: Bool = false
        var loadErrorMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case refreshRequested
        case tablesLoaded([TableInfo])
        case tablesFailedToLoad(String)
        case tableSelected(TableInfo.ID?)
    }

    @Dependency(\.database) var database

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .refreshRequested:
                state.isLoading = true
                state.loadErrorMessage = nil
                let url = state.databaseURL
                return .run { send in
                    do {
                        let tables = try await database.tables(url)
                        await send(.tablesLoaded(tables))
                    } catch {
                        await send(.tablesFailedToLoad(error.localizedDescription))
                    }
                }

            case let .tablesLoaded(tables):
                state.tables = tables
                state.isLoading = false
                if state.selectedTableID == nil {
                    state.selectedTableID = tables.first?.id
                }
                return .none

            case let .tablesFailedToLoad(message):
                state.loadErrorMessage = message
                state.isLoading = false
                return .none

            case let .tableSelected(id):
                state.selectedTableID = id
                return .none
            }
        }
    }
}
