import ComposableArchitecture
import Foundation
import GRDB

struct DatabaseClient: Sendable {
    var tables: @Sendable (URL) async throws -> [TableInfo]
    var close: @Sendable (URL) async -> Void
}

extension DatabaseClient: DependencyKey {
    static let liveValue: DatabaseClient = {
        let registry = DatabaseRegistry()
        return DatabaseClient(
            tables: { url in try await registry.tables(for: url) },
            close: { url in await registry.close(url) }
        )
    }()

    static let testValue = DatabaseClient(
        tables: unimplemented("DatabaseClient.tables"),
        close: unimplemented("DatabaseClient.close")
    )
}

extension DependencyValues {
    var database: DatabaseClient {
        get { self[DatabaseClient.self] }
        set { self[DatabaseClient.self] = newValue }
    }
}

private actor DatabaseRegistry {
    private var queues: [URL: DatabaseQueue] = [:]

    func queue(for url: URL) throws -> DatabaseQueue {
        if let existing = queues[url] { return existing }
        var config = Configuration()
        config.readonly = true
        let q = try DatabaseQueue(path: url.path, configuration: config)
        queues[url] = q
        return q
    }

    func tables(for url: URL) async throws -> [TableInfo] {
        let q = try queue(for: url)
        return try await q.read { db in
            try SchemaInspector.listTables(db)
        }
    }

    func close(_ url: URL) {
        queues.removeValue(forKey: url)
    }
}
