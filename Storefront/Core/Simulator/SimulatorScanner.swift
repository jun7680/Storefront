import Foundation

enum SimulatorScanner {
    static func scan() throws -> [SimulatorDevice] {
        let devicesByRuntime = try fetchDeviceList()
        var devices: [SimulatorDevice] = []

        for (runtime, deviceEntries) in devicesByRuntime {
            for entry in deviceEntries {
                let apps = entry.isBooted ? (try? scanApps(udid: entry.udid)) ?? [] : []
                devices.append(
                    SimulatorDevice(
                        id: entry.udid,
                        name: entry.name,
                        runtime: prettifyRuntime(runtime),
                        isBooted: entry.isBooted,
                        apps: apps
                    )
                )
            }
        }

        return devices.sorted { lhs, rhs in
            if lhs.isBooted != rhs.isBooted { return lhs.isBooted && !rhs.isBooted }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    fileprivate struct DeviceEntry {
        let udid: String
        let name: String
        let isBooted: Bool
    }

    fileprivate static func fetchDeviceList() throws -> [String: [DeviceEntry]] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "list", "devices", "--json"]
        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw SimulatorError.commandFailed(code: Int(process.terminationStatus))
        }

        let data = try stdout.fileHandleForReading.readToEnd() ?? Data()
        return try parseDeviceList(data)
    }

    fileprivate static func parseDeviceList(_ data: Data) throws -> [String: [DeviceEntry]] {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let devicesByRuntime = json["devices"] as? [String: [[String: Any]]]
        else {
            throw SimulatorError.parseFailed
        }

        var result: [String: [DeviceEntry]] = [:]
        for (runtime, entries) in devicesByRuntime {
            var list: [DeviceEntry] = []
            for entry in entries {
                guard
                    let udid = entry["udid"] as? String,
                    let name = entry["name"] as? String
                else { continue }
                let state = entry["state"] as? String ?? ""
                list.append(
                    DeviceEntry(udid: udid, name: name, isBooted: state == "Booted")
                )
            }
            if !list.isEmpty {
                result[runtime] = list
            }
        }
        return result
    }

    private static func scanApps(udid: String) throws -> [SimulatorApp] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let containersRoot = home.appending(path: "Library/Developer/CoreSimulator/Devices/\(udid)/data/Containers/Data/Application", directoryHint: .isDirectory)

        guard FileManager.default.fileExists(atPath: containersRoot.path) else { return [] }

        let containers = try FileManager.default.contentsOfDirectory(at: containersRoot, includingPropertiesForKeys: nil)
        var apps: [SimulatorApp] = []

        for containerURL in containers {
            let containerID = containerURL.lastPathComponent
            let metadataURL = containerURL.appending(path: ".com.apple.mobile_container_manager.metadata.plist")
            guard let bundleID = readBundleID(from: metadataURL) else { continue }

            let databases = findDatabases(under: containerURL)
            guard !databases.isEmpty else { continue }

            apps.append(
                SimulatorApp(
                    containerID: containerID,
                    bundleID: bundleID,
                    databases: databases
                )
            )
        }

        return apps.sorted { $0.bundleID.localizedCaseInsensitiveCompare($1.bundleID) == .orderedAscending }
    }

    private static func readBundleID(from plistURL: URL) -> String? {
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return plist["MCMMetadataIdentifier"] as? String
    }

    private static let databaseExtensions: Set<String> = ["sqlite", "sqlite3", "db", "store"]

    private static func findDatabases(under containerURL: URL) -> [DatabaseFile] {
        let fm = FileManager.default
        let roots = [
            containerURL.appending(path: "Documents"),
            containerURL.appending(path: "Library"),
            containerURL.appending(path: "tmp")
        ].filter { fm.fileExists(atPath: $0.path) }

        var found: [DatabaseFile] = []
        for root in roots {
            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for case let url as URL in enumerator {
                guard databaseExtensions.contains(url.pathExtension.lowercased()) else { continue }
                // Skip WAL/SHM siblings
                let stem = url.deletingPathExtension().lastPathComponent
                if stem.hasSuffix("-wal") || stem.hasSuffix("-shm") { continue }

                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
                guard values?.isRegularFile == true else { continue }

                let size = Int64(values?.fileSize ?? 0)
                let mtime = values?.contentModificationDate ?? .distantPast
                found.append(DatabaseFile(url: url, sizeBytes: size, modifiedAt: mtime))
            }
        }

        return found.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    private static func prettifyRuntime(_ runtime: String) -> String {
        // "com.apple.CoreSimulator.SimRuntime.iOS-18-0" → "iOS 18.0"
        let trimmed = runtime.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
        let parts = trimmed.split(separator: "-")
        guard parts.count >= 2 else { return trimmed }
        let platform = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(platform) \(version)"
    }
}

enum SimulatorError: Error, LocalizedError, Equatable {
    case commandFailed(code: Int)
    case parseFailed

    var errorDescription: String? {
        switch self {
        case .commandFailed(let code): return "xcrun simctl 실패 (코드 \(code))"
        case .parseFailed: return "시뮬레이터 목록을 해석할 수 없습니다"
        }
    }
}

extension SimulatorScanner {
    struct DeviceEntryForTesting: Equatable {
        let udid: String
        let name: String
        let isBooted: Bool
    }

    static func parseForTesting(_ data: Data) throws -> [String: [DeviceEntryForTesting]] {
        let parsed = try parseDeviceList(data)
        return parsed.mapValues { entries in
            entries.map { DeviceEntryForTesting(udid: $0.udid, name: $0.name, isBooted: $0.isBooted) }
        }
    }
}
