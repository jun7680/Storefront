import ComposableArchitecture
import XCTest
@testable import Storefront

@MainActor
final class BrowserFeatureTests: XCTestCase {
    func testOnAppearLoadsTables() async {
        let sampleTables = [
            TableInfo(name: "artists", kind: .table, rowCount: 275),
            TableInfo(name: "tracks", kind: .table, rowCount: 3_503)
        ]
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")

        let store = TestStore(
            initialState: BrowserFeature.State(databaseURL: url)
        ) {
            BrowserFeature()
        } withDependencies: {
            $0.database.tables = { @Sendable _ in sampleTables }
            $0.database.close = { @Sendable _ in }
        }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.tablesLoaded) {
            $0.isLoading = false
            $0.tables = sampleTables
            $0.selectedTableID = "artists"
        }
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
            $0.database.tables = { @Sendable _ in throw SampleError() }
            $0.database.close = { @Sendable _ in }
        }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.tablesFailedToLoad) {
            $0.isLoading = false
            $0.loadErrorMessage = "disk corrupted"
        }
    }

    func testTableSelectionUpdatesState() async {
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")
        let store = TestStore(
            initialState: BrowserFeature.State(
                databaseURL: url,
                tables: [TableInfo(name: "a", kind: .table, rowCount: 1)],
                selectedTableID: nil
            )
        ) {
            BrowserFeature()
        }

        await store.send(.tableSelected("a")) {
            $0.selectedTableID = "a"
        }
    }
}
