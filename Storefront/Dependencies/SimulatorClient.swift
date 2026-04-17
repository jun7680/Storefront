import ComposableArchitecture
import Foundation

struct SimulatorClient: Sendable {
    var scan: @Sendable () async throws -> [SimulatorDevice]
}

extension SimulatorClient: DependencyKey {
    static let liveValue = SimulatorClient(
        scan: {
            try await Task.detached(priority: .userInitiated) {
                try SimulatorScanner.scan()
            }.value
        }
    )

    static let testValue = SimulatorClient(
        scan: unimplemented("SimulatorClient.scan", placeholder: [])
    )
}

extension DependencyValues {
    var simulator: SimulatorClient {
        get { self[SimulatorClient.self] }
        set { self[SimulatorClient.self] = newValue }
    }
}
