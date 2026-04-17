import Foundation
import GRDB

struct TableInfo: Equatable, Identifiable, Sendable {
    let name: String
    let kind: Kind
    let rowCount: Int
    let classification: Classification

    var id: String { name }

    var displayName: String {
        switch classification {
        case .swiftDataEntity: return SwiftDataDecoder.normalize(tableName: name)
        default: return name
        }
    }

    enum Kind: String, Sendable, Equatable {
        case table
        case view
    }

    enum Classification: Sendable, Equatable {
        case standard
        case swiftDataEntity
        case swiftDataSystem
    }
}

struct DatabaseSchema: Equatable, Sendable {
    let kind: DatabaseKind
    let tables: [TableInfo]
}

enum SchemaInspector {
    static func inspect(_ db: Database) throws -> DatabaseSchema {
        let kind = try SwiftDataDetector.kind(db)
        let tables = try listTables(db, kind: kind)
        return DatabaseSchema(kind: kind, tables: tables)
    }

    static func listTables(_ db: Database, kind: DatabaseKind = .standard) throws -> [TableInfo] {
        let metaRows = try Row.fetchAll(db, sql: """
            SELECT name, type FROM sqlite_master
            WHERE type IN ('table', 'view')
              AND name NOT LIKE 'sqlite_%'
            ORDER BY type DESC, name ASC
            """)

        return metaRows.map { row in
            let name: String = row["name"]
            let type: String = row["type"]
            let tkind: TableInfo.Kind = (type == "view") ? .view : .table
            let escaped = name.replacingOccurrences(of: "\"", with: "\"\"")
            let count = (try? Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"\(escaped)\"")) ?? 0
            let classification = SwiftDataDetector.classify(tableName: name, kind: kind)
            return TableInfo(name: name, kind: tkind, rowCount: count, classification: classification)
        }
    }
}
