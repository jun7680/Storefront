import Foundation
import GRDB

enum DatabaseKind: Equatable, Sendable {
    case standard
    case swiftData
}

enum SwiftDataDetector {
    static func kind(_ db: Database) throws -> DatabaseKind {
        let count = try Int.fetchOne(
            db,
            sql: """
            SELECT COUNT(*) FROM sqlite_master
            WHERE type = 'table'
              AND name IN ('Z_METADATA', 'Z_PRIMARYKEY', 'Z_MODELCACHE')
            """
        ) ?? 0
        return count >= 2 ? .swiftData : .standard
    }

    static func classify(tableName: String, kind: DatabaseKind) -> TableInfo.Classification {
        guard kind == .swiftData else { return .standard }
        let systemNames: Set<String> = ["Z_METADATA", "Z_PRIMARYKEY", "Z_MODELCACHE"]
        if systemNames.contains(tableName) { return .swiftDataSystem }
        if tableName.hasPrefix("Z_") { return .swiftDataSystem }
        if tableName.hasPrefix("Z"), tableName.count > 1 {
            let second = tableName.index(after: tableName.startIndex)
            if tableName[second].isLetter, tableName[second].isUppercase {
                return .swiftDataEntity
            }
        }
        return .standard
    }
}
