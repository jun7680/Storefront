import ComposableArchitecture
import Foundation

@Reducer
struct SimulatorPickerFeature {
    @ObservableState
    struct State: Equatable {
        var devices: [SimulatorDevice] = []
        var isLoading: Bool = false
        var errorMessage: String?
        var expandedDeviceIDs: Set<String> = []
        var expandedAppIDs: Set<String> = []
    }

    enum Action: Equatable {
        case onAppear
        case refreshRequested
        case scanned([SimulatorDevice])
        case scanFailed(String)
        case toggleDevice(String)
        case toggleApp(String)
        case databasePicked(URL)
        case dismissTapped
    }

    @Dependency(\.simulator) var simulator

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .refreshRequested:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let devices = try await simulator.scan()
                        await send(.scanned(devices))
                    } catch {
                        await send(.scanFailed(error.localizedDescription))
                    }
                }

            case let .scanned(devices):
                state.devices = devices
                state.isLoading = false
                state.expandedDeviceIDs = Set(devices.filter { $0.isBooted && !$0.apps.isEmpty }.map(\.id))
                return .none

            case let .scanFailed(message):
                state.errorMessage = message
                state.isLoading = false
                return .none

            case let .toggleDevice(id):
                if state.expandedDeviceIDs.contains(id) {
                    state.expandedDeviceIDs.remove(id)
                } else {
                    state.expandedDeviceIDs.insert(id)
                }
                return .none

            case let .toggleApp(id):
                if state.expandedAppIDs.contains(id) {
                    state.expandedAppIDs.remove(id)
                } else {
                    state.expandedAppIDs.insert(id)
                }
                return .none

            case .databasePicked, .dismissTapped:
                // Handled by parent
                return .none
            }
        }
    }
}
