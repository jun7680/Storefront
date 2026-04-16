import Foundation
import GRDB

struct TableInfo: Equatable, Identifiable, Sendable {
    let name: String
    let kind: Kind
    let rowCount: Int

    var id: String { name }

    enum Kind: String, Sendable, Equatable {
        case table
        case view
    }
}

enum SchemaInspector {
    static func listTables(_ db: Database) throws -> [TableInfo] {
        let metaRows = try Row.fetchAll(db, sql: """
            SELECT name, type FROM sqlite_master
            WHERE type IN ('table', 'view')
              AND name NOT LIKE 'sqlite_%'
            ORDER BY type DESC, name ASC
            """)

        return metaRows.map { row in
            let name: String = row["name"]
            let type: String = row["type"]
            let kind: TableInfo.Kind = (type == "view") ? .view : .table
            let escaped = name.replacingOccurrences(of: "\"", with: "\"\"")
            let count = (try? Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"\(escaped)\"")) ?? 0
            return TableInfo(name: name, kind: kind, rowCount: count)
        }
    }
}
