import Foundation

struct SimulatorDevice: Equatable, Identifiable, Sendable {
    let id: String          // UDID
    let name: String        // "iPhone 17"
    let runtime: String     // "iOS 18.0"
    let isBooted: Bool
    var apps: [SimulatorApp] = []
}

struct SimulatorApp: Equatable, Identifiable, Sendable {
    let containerID: String   // Application UUID folder name
    let bundleID: String
    let databases: [DatabaseFile]

    var id: String { containerID }
    var displayName: String { bundleID }
}

struct DatabaseFile: Equatable, Identifiable, Sendable, Hashable {
    let url: URL
    let sizeBytes: Int64
    let modifiedAt: Date

    var id: URL { url }
    var displayName: String { url.lastPathComponent }
}
