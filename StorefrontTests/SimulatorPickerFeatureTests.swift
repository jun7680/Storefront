import ComposableArchitecture
import XCTest
@testable import Storefront

@MainActor
final class SimulatorPickerFeatureTests: XCTestCase {
    func testOnAppearLoadsDevicesAndAutoExpandsBootedOnes() async {
        let booted = SimulatorDevice(
            id: "device-1",
            name: "iPhone 17",
            runtime: "iOS 18.0",
            isBooted: true,
            apps: [
                SimulatorApp(
                    containerID: "app-A",
                    bundleID: "com.example.MyApp",
                    databases: [
                        DatabaseFile(
                            url: URL(fileURLWithPath: "/tmp/a.sqlite"),
                            sizeBytes: 1024,
                            modifiedAt: Date(timeIntervalSince1970: 0)
                        )
                    ]
                )
            ]
        )
        let shutdown = SimulatorDevice(
            id: "device-2",
            name: "iPad Air",
            runtime: "iPadOS 18.0",
            isBooted: false,
            apps: []
        )

        let store = TestStore(initialState: SimulatorPickerFeature.State()) {
            SimulatorPickerFeature()
        } withDependencies: {
            $0.simulator.scan = { @Sendable in [booted, shutdown] }
        }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.scanned) {
            $0.isLoading = false
            $0.devices = [booted, shutdown]
            $0.expandedDeviceIDs = ["device-1"]
        }
    }

    func testToggleDeviceAddsAndRemoves() async {
        let store = TestStore(initialState: SimulatorPickerFeature.State()) {
            SimulatorPickerFeature()
        }

        await store.send(.toggleDevice("d-1")) {
            $0.expandedDeviceIDs = ["d-1"]
        }
        await store.send(.toggleDevice("d-1")) {
            $0.expandedDeviceIDs = []
        }
    }

    func testParseDeviceListExtractsBootedFlag() throws {
        let jsonString = """
        {"devices": {
          "com.apple.CoreSimulator.SimRuntime.iOS-18-0": [
            {"udid": "A", "name": "iPhone 17", "state": "Booted"},
            {"udid": "B", "name": "iPhone 16", "state": "Shutdown"}
          ]
        }}
        """
        let data = Data(jsonString.utf8)
        let parsed = try SimulatorScanner.parseForTesting(data)
        let runtime = try XCTUnwrap(parsed["com.apple.CoreSimulator.SimRuntime.iOS-18-0"])
        XCTAssertEqual(runtime.count, 2)
        XCTAssertTrue(runtime.first { $0.udid == "A" }?.isBooted ?? false)
        XCTAssertFalse(runtime.first { $0.udid == "B" }?.isBooted ?? true)
    }
}
