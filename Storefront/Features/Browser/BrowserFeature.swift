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

        var currentPage: RowPage?
        var isLoadingRows: Bool = false
        var rowLoadError: String?

        var liveReloadToast: Int = 0
    }

    enum Action: Equatable {
        case onAppear
        case onDisappear
        case refreshRequested
        case tablesLoaded([TableInfo])
        case tablesFailedToLoad(String)
        case tableSelected(TableInfo.ID?)
        case rowsLoaded(RowPage)
        case rowsFailedToLoad(String)
        case fileChanged
    }

    @Dependency(\.database) var database
    @Dependency(\.fileWatcher) var fileWatcher

    enum CancelID: Hashable {
        case watch
        case loadRows
    }

    private let pageSize: Int = 200

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.loadErrorMessage = nil
                let url = state.databaseURL
                return .merge(
                    loadTables(url: url),
                    .run { send in
                        for await _ in fileWatcher.changes(url) {
                            await send(.fileChanged)
                        }
                    }
                    .cancellable(id: CancelID.watch, cancelInFlight: true)
                )

            case .onDisappear:
                return .cancel(id: CancelID.watch)

            case .refreshRequested:
                state.isLoading = true
                state.loadErrorMessage = nil
                let url = state.databaseURL
                let selected = state.selectedTableID
                return .merge(
                    loadTables(url: url),
                    selected.map { loadRows(url: url, table: $0) } ?? .none
                )

            case let .tablesLoaded(tables):
                state.tables = tables
                state.isLoading = false
                let autoSelected: String?
                if let current = state.selectedTableID, tables.contains(where: { $0.id == current }) {
                    autoSelected = current
                } else {
                    autoSelected = tables.first?.id
                }
                state.selectedTableID = autoSelected
                if let table = autoSelected {
                    state.isLoadingRows = true
                    state.rowLoadError = nil
                    return loadRows(url: state.databaseURL, table: table)
                }
                return .none

            case let .tablesFailedToLoad(message):
                state.loadErrorMessage = message
                state.isLoading = false
                return .none

            case let .tableSelected(id):
                state.selectedTableID = id
                state.currentPage = nil
                state.rowLoadError = nil
                guard let id else { return .none }
                state.isLoadingRows = true
                return loadRows(url: state.databaseURL, table: id)

            case let .rowsLoaded(page):
                state.currentPage = page
                state.isLoadingRows = false
                state.rowLoadError = nil
                return .none

            case let .rowsFailedToLoad(message):
                state.rowLoadError = message
                state.isLoadingRows = false
                return .none

            case .fileChanged:
                state.liveReloadToast &+= 1
                let url = state.databaseURL
                let selected = state.selectedTableID
                return .merge(
                    loadTables(url: url),
                    selected.map { loadRows(url: url, table: $0) } ?? .none
                )
            }
        }
    }

    private func loadTables(url: URL) -> Effect<Action> {
        .run { send in
            do {
                let tables = try await database.tables(url)
                await send(.tablesLoaded(tables))
            } catch {
                await send(.tablesFailedToLoad(error.localizedDescription))
            }
        }
    }

    private func loadRows(url: URL, table: String) -> Effect<Action> {
        .run { [pageSize] send in
            do {
                let page = try await database.page(url, table, 0, pageSize)
                await send(.rowsLoaded(page))
            } catch {
                await send(.rowsFailedToLoad(error.localizedDescription))
            }
        }
        .cancellable(id: CancelID.loadRows, cancelInFlight: true)
    }
}
