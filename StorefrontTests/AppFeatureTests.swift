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

    func testFileImportedOpensBrowser() async {
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")
        let store = TestStore(
            initialState: AppFeature.State(isFileImporterPresented: true)
        ) {
            AppFeature()
        }
        store.exhaustivity = .off

        await store.send(.fileImported(url)) {
            $0.isFileImporterPresented = false
            $0.browser = BrowserFeature.State(databaseURL: url)
        }
    }

    func testCloseDocumentClearsBrowser() async {
        let url = URL(fileURLWithPath: "/tmp/sample.sqlite")
        let store = TestStore(
            initialState: AppFeature.State(
                browser: BrowserFeature.State(databaseURL: url)
            )
        ) {
            AppFeature()
        }

        await store.send(.closeDocument) {
            $0.browser = nil
        }
    }
}
