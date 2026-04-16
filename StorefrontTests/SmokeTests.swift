import ComposableArchitecture
import XCTest
@testable import Storefront

@MainActor
final class SmokeTests: XCTestCase {
    func testInitialStateHasNoDocument() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        XCTAssertNil(store.state.currentDocumentURL)
        XCTAssertFalse(store.state.isFileImporterPresented)
    }

    func testOpenButtonPresentsFileImporter() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        await store.send(.openButtonTapped) {
            $0.isFileImporterPresented = true
        }
    }

    func testFileImportedSetsDocumentURL() async {
        let store = TestStore(
            initialState: AppFeature.State(isFileImporterPresented: true)
        ) {
            AppFeature()
        }
        let url = URL(fileURLWithPath: "/tmp/test.sqlite")
        await store.send(.fileImported(.success(url))) {
            $0.currentDocumentURL = url
            $0.isFileImporterPresented = false
        }
    }
}
