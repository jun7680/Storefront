import ComposableArchitecture
import XCTest
@testable import Storefront

@MainActor
final class BrowserFeatureTests: XCTestCase {
    func testOnAppearLoadsTablesAndAutoSelectsFirst() async {
        let sampleTables = [
            TableInfo(name: "artists", kind: .table, rowCount: 275, classification: .standard),
            TableInfo(name: "tracks", kind: .table, rowCount: 3_503, classification: .standard)
        ]
        let samplePage = RowPage(
            columns: [ColumnInfo(name: "id", declaredType: "INTEGER", isPrimaryKey: true, isNotNull: true, isSwiftDataEntity: false)],
            rows: [RowSnapshot(index: 0, values: [.integer(1)])],
            totalRows: 1,
            offset: 0,
            limit: 200
        )
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")

        let store = TestStore(
            initialState: BrowserFeature.State(databaseURL: url)
        ) {
            BrowserFeature()
        } withDependencies: {
            $0.database.inspect = { @Sendable _ in DatabaseSchema(kind: .standard, tables: sampleTables) }
            $0.database.page = { @Sendable _, _, _, _, _ in samplePage }
            $0.database.close = { @Sendable _ in }
            $0.fileWatcher.changes = { @Sendable _ in AsyncStream { _ in } }
        }
        store.exhaustivity = .off

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.schemaLoaded) {
            $0.isLoading = false
            $0.tables = sampleTables
            $0.databaseKind = .standard
            $0.selectedTableID = "artists"
            $0.isLoadingRows = true
        }
        await store.receive(\.rowsLoaded) {
            $0.isLoadingRows = false
            $0.currentPage = samplePage
        }
        await store.send(.onDisappear)
    }

    func testOnAppearPropagatesFailure() async {
        struct SampleError: LocalizedError {
            var errorDescription: String? { "disk corrupted" }
        }
        let url = URL(fileURLWithPath: "/tmp/broken.sqlite")

        let store = TestStore(
            initialState: BrowserFeature.State(databaseURL: url)
        ) {
            BrowserFeature()
        } withDependencies: {
            $0.database.inspect = { @Sendable _ in throw SampleError() }
            $0.database.page = { @Sendable _, _, _, _, _ in
                throw SampleError()
            }
            $0.database.close = { @Sendable _ in }
            $0.fileWatcher.changes = { @Sendable _ in AsyncStream { _ in } }
        }
        store.exhaustivity = .off

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.schemaFailedToLoad) {
            $0.isLoading = false
            $0.loadErrorMessage = "disk corrupted"
        }
        await store.send(.onDisappear)
    }

    func testTableSelectionTriggersRowLoad() async {
        let samplePage = RowPage(
            columns: [ColumnInfo(name: "id", declaredType: "INTEGER", isPrimaryKey: true, isNotNull: true, isSwiftDataEntity: false)],
            rows: [RowSnapshot(index: 0, values: [.integer(42)])],
            totalRows: 1,
            offset: 0,
            limit: 200
        )
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")

        let store = TestStore(
            initialState: BrowserFeature.State(
                databaseURL: url,
                tables: [TableInfo(name: "a", kind: .table, rowCount: 1, classification: .standard)],
                selectedTableID: nil
            )
        ) {
            BrowserFeature()
        } withDependencies: {
            $0.database.page = { @Sendable _, _, _, _, _ in samplePage }
        }

        await store.send(.tableSelected("a")) {
            $0.selectedTableID = "a"
            $0.isLoadingRows = true
        }
        await store.receive(\.rowsLoaded) {
            $0.isLoadingRows = false
            $0.currentPage = samplePage
        }
    }

    func testFileChangedIncrementsToastCounter() async {
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")
        let store = TestStore(
            initialState: BrowserFeature.State(
                databaseURL: url,
                tables: [TableInfo(name: "a", kind: .table, rowCount: 1, classification: .standard)],
                selectedTableID: "a"
            )
        ) {
            BrowserFeature()
        } withDependencies: {
            $0.database.inspect = { @Sendable _ in
                DatabaseSchema(
                    kind: .standard,
                    tables: [TableInfo(name: "a", kind: .table, rowCount: 2, classification: .standard)]
                )
            }
            $0.database.page = { @Sendable _, _, _, _, _ in
                RowPage(columns: [], rows: [], totalRows: 0, offset: 0, limit: 200)
            }
        }
        store.exhaustivity = .off

        await store.send(.fileChanged) {
            $0.liveReloadToast = 1
        }
    }
}
