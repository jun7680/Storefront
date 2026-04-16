import ComposableArchitecture
import Foundation
import GRDB

struct DatabaseClient: Sendable {
    var tables: @Sendable (URL) async throws -> [TableInfo]
    var page: @Sendable (_ url: URL, _ table: String, _ offset: Int, _ limit: Int) async throws -> RowPage
    var close: @Sendable (URL) async -> Void
}

extension DatabaseClient: DependencyKey {
    static let liveValue: DatabaseClient = {
        let registry = DatabaseRegistry()
        return DatabaseClient(
            tables: { url in try await registry.tables(for: url) },
            page: { url, table, offset, limit in
                try await registry.page(url: url, table: table, offset: offset, limit: limit)
            },
            close: { url in await registry.close(url) }
        )
    }()

    static let testValue = DatabaseClient(
        tables: unimplemented("DatabaseClient.tables"),
        page: unimplemented("DatabaseClient.page"),
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

    func page(url: URL, table: String, offset: Int, limit: Int) async throws -> RowPage {
        let q = try queue(for: url)
        return try await q.read { db in
            try RowFetcher.page(db, table: table, offset: offset, limit: limit)
        }
    }

    func close(_ url: URL) {
        queues.removeValue(forKey: url)
    }
}
