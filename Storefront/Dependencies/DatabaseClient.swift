import ComposableArchitecture
import Foundation
import GRDB

struct DatabaseClient: Sendable {
    var inspect: @Sendable (URL) async throws -> DatabaseSchema
    var page: @Sendable (_ url: URL, _ table: String, _ offset: Int, _ limit: Int, _ isSwiftDataEntity: Bool) async throws -> RowPage
    var close: @Sendable (URL) async -> Void
}

extension DatabaseClient: DependencyKey {
    static let liveValue: DatabaseClient = {
        let registry = DatabaseRegistry()
        return DatabaseClient(
            inspect: { url in try await registry.inspect(url: url) },
            page: { url, table, offset, limit, isEntity in
                try await registry.page(url: url, table: table, offset: offset, limit: limit, isEntity: isEntity)
            },
            close: { url in await registry.close(url) }
        )
    }()

    static let testValue = DatabaseClient(
        inspect: unimplemented("DatabaseClient.inspect"),
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
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA query_only = ON")
        }
        let q = try DatabaseQueue(path: url.path, configuration: config)
        queues[url] = q
        return q
    }

    func inspect(url: URL) async throws -> DatabaseSchema {
        let q = try queue(for: url)
        return try await q.read { db in
            try SchemaInspector.inspect(db)
        }
    }

    func page(url: URL, table: String, offset: Int, limit: Int, isEntity: Bool) async throws -> RowPage {
        let q = try queue(for: url)
        return try await q.read { db in
            try RowFetcher.page(db, table: table, offset: offset, limit: limit, isSwiftDataEntity: isEntity)
        }
    }

    func close(_ url: URL) {
        queues.removeValue(forKey: url)
    }
}
