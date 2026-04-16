import XCTest
@testable import Storefront

final class SmokeTests: XCTestCase {
    func testAppStateInitialValues() {
        let state = AppState()
        XCTAssertFalse(state.openFileRequested)
        XCTAssertFalse(state.reloadRequested)
        XCTAssertNil(state.currentDocumentURL)
    }
}
