import Foundation
import Observation

@Observable
final class AppState {
    var openFileRequested: Bool = false
    var reloadRequested: Bool = false
    var currentDocumentURL: URL?
}
