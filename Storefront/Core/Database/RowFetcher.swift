import Foundation
import GRDB

struct ColumnInfo: Equatable, Identifiable, Sendable {
    let name: String
    let declaredType: String
    let isPrimaryKey: Bool
    let isNotNull: Bool

    var id: String { name }
}

enum DBValue: Equatable, Sendable, Hashable {
    case null
    case integer(Int64)
    case double(Double)
    case text(String)
    case blob(Data)

    var displayKind: Kind {
        switch self {
        case .null: return .null
        case .integer: return .integer
        case .double: return .real
        case .text: return .text
        case .blob: return .blob
        }
    }

    enum Kind: Sendable, Equatable {
        case null, integer, real, text, blob
    }
}

struct RowSnapshot: Equatable, Identifiable, Sendable {
    let index: Int
    let values: [DBValue]

    var id: Int { index }
}

struct RowPage: Equatable, Sendable {
    let columns: [ColumnInfo]
    let rows: [RowSnapshot]
    let totalRows: Int
    let offset: Int
    let limit: Int
}

enum RowFetcher {
    static func columns(_ db: Database, table: String) throws -> [ColumnInfo] {
        let escaped = table.replacingOccurrences(of: "\"", with: "\"\"")
        let rows = try Row.fetchAll(db, sql: "PRAGMA table_info(\"\(escaped)\")")
        return rows.map { row in
            ColumnInfo(
                name: row["name"],
                declaredType: (row["type"] as String?) ?? "",
                isPrimaryKey: ((row["pk"] as Int?) ?? 0) > 0,
                isNotNull: ((row["notnull"] as Int?) ?? 0) != 0
            )
        }
    }

    static func page(_ db: Database, table: String, offset: Int, limit: Int) throws -> RowPage {
        let columns = try columns(db, table: table)
        let escaped = table.replacingOccurrences(of: "\"", with: "\"\"")

        let total = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \"\(escaped)\"") ?? 0

        let rows = try Row.fetchAll(
            db,
            sql: "SELECT * FROM \"\(escaped)\" LIMIT ? OFFSET ?",
            arguments: [limit, offset]
        )

        let snapshots = rows.enumerated().map { (idx, row) in
            let values: [DBValue] = columns.map { col in
                let dbValue = row[col.name] as DatabaseValue?
                return mapValue(dbValue ?? DatabaseValue.null)
            }
            return RowSnapshot(index: offset + idx, values: values)
        }

        return RowPage(
            columns: columns,
            rows: snapshots,
            totalRows: total,
            offset: offset,
            limit: limit
        )
    }

    private static func mapValue(_ value: DatabaseValue) -> DBValue {
        switch value.storage {
        case .null: return .null
        case .int64(let v): return .integer(v)
        case .double(let v): return .double(v)
        case .string(let v): return .text(v)
        case .blob(let v): return .blob(v)
        }
    }
}
