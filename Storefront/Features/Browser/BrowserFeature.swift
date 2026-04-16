import ComposableArchitecture
import Foundation

@Reducer
struct BrowserFeature {
    @ObservableState
    struct State: Equatable {
        let databaseURL: URL
        var databaseKind: DatabaseKind = .standard
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
        case schemaLoaded(DatabaseSchema)
        case schemaFailedToLoad(String)
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
                    loadSchema(url: url),
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
                let selected = resolveSelectedTable(in: state)
                return .merge(
                    loadSchema(url: url),
                    selected.map { loadRows(url: url, table: $0.name, isEntity: $0.classification == .swiftDataEntity) } ?? .none
                )

            case let .schemaLoaded(schema):
                state.tables = schema.tables
                state.databaseKind = schema.kind
                state.isLoading = false
                let autoSelectedID: String?
                if let current = state.selectedTableID, schema.tables.contains(where: { $0.id == current }) {
                    autoSelectedID = current
                } else {
                    // Prefer non-system tables on SwiftData stores
                    autoSelectedID = schema.tables.first(where: { $0.classification != .swiftDataSystem })?.id
                        ?? schema.tables.first?.id
                }
                state.selectedTableID = autoSelectedID
                if let id = autoSelectedID, let table = schema.tables.first(where: { $0.id == id }) {
                    state.isLoadingRows = true
                    state.rowLoadError = nil
                    return loadRows(url: state.databaseURL, table: table.name, isEntity: table.classification == .swiftDataEntity)
                }
                return .none

            case let .schemaFailedToLoad(message):
                state.loadErrorMessage = message
                state.isLoading = false
                return .none

            case let .tableSelected(id):
                state.selectedTableID = id
                state.currentPage = nil
                state.rowLoadError = nil
                guard let id, let table = state.tables.first(where: { $0.id == id }) else { return .none }
                state.isLoadingRows = true
                return loadRows(url: state.databaseURL, table: table.name, isEntity: table.classification == .swiftDataEntity)

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
                let selected = resolveSelectedTable(in: state)
                return .merge(
                    loadSchema(url: url),
                    selected.map { loadRows(url: url, table: $0.name, isEntity: $0.classification == .swiftDataEntity) } ?? .none
                )
            }
        }
    }

    private func resolveSelectedTable(in state: State) -> TableInfo? {
        guard let id = state.selectedTableID else { return nil }
        return state.tables.first { $0.id == id }
    }

    private func loadSchema(url: URL) -> Effect<Action> {
        .run { send in
            do {
                let schema = try await database.inspect(url)
                await send(.schemaLoaded(schema))
            } catch {
                await send(.schemaFailedToLoad(error.localizedDescription))
            }
        }
    }

    private func loadRows(url: URL, table: String, isEntity: Bool) -> Effect<Action> {
        .run { [pageSize] send in
            do {
                let page = try await database.page(url, table, 0, pageSize, isEntity)
                await send(.rowsLoaded(page))
            } catch {
                await send(.rowsFailedToLoad(error.localizedDescription))
            }
        }
        .cancellable(id: CancelID.loadRows, cancelInFlight: true)
    }
}
