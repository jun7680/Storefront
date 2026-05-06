import ComposableArchitecture
import XCTest
@testable import Storefront

@MainActor
final class AppFeatureTests: XCTestCase {
    func testOpenButtonPresentsFileImporter() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.openButtonTapped) {
            $0.isFileImporterPresented = true
        }
    }

    func testFileImportedAppendsTab() async {
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")
        let store = TestStore(
            initialState: AppFeature.State(isFileImporterPresented: true)
        ) {
            AppFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        store.exhaustivity = .off

        let expectedID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

        await store.send(.fileImported(url)) {
            $0.isFileImporterPresented = false
            $0.tabs = [BrowserTab.State(id: expectedID, databaseURL: url)]
            $0.selectedTabID = expectedID
        }
    }

    func testCloseCurrentTabRemovesSelectedTab() async {
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let store = TestStore(
            initialState: AppFeature.State(
                tabs: [BrowserTab.State(id: id, databaseURL: url)],
                selectedTabID: id
            )
        ) {
            AppFeature()
        }

        await store.send(.closeCurrentTab) {
            $0.tabs = []
            $0.selectedTabID = nil
        }
    }
}
