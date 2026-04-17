import Foundation

enum SwiftDataDecoder {
    /// SwiftData 엔티티 테이블명에서 `Z` 접두어를 제거한다. 예: `ZTASK` → `Task`.
    static func normalize(tableName: String) -> String {
        guard tableName.hasPrefix("Z"), tableName.count > 1 else { return tableName }
        let withoutPrefix = tableName.dropFirst()
        let lower = withoutPrefix.lowercased()
        guard let first = lower.first else { return tableName }
        return first.uppercased() + lower.dropFirst()
    }

    /// SwiftData 엔티티 컬럼명에서 `Z` 접두어를 제거한다. 예: `ZNAME` → `name`, `ZCREATEDAT` → `createdAt`.
    /// SwiftData 내부 컬럼(Z_PK, Z_ENT, Z_OPT 등)은 정규화하지 않고 그대로 반환.
    static func normalize(columnName: String) -> String {
        let systemPrefixes = ["Z_PK", "Z_ENT", "Z_OPT", "Z_NAME", "Z_SUPER", "Z_MAX"]
        if systemPrefixes.contains(columnName) { return columnName }
        if columnName.hasPrefix("Z_") { return columnName }
        guard columnName.hasPrefix("Z"), columnName.count > 1 else { return columnName }

        let rest = String(columnName.dropFirst())
        // ZCREATEDAT → createdAt (best-effort heuristic for all-caps legacy SwiftData columns)
        if rest == rest.uppercased() {
            return rest.lowercased()
        }
        // Already mixed case (e.g. ZcreatedAt) — just lowercase first char
        return rest.prefix(1).lowercased() + rest.dropFirst()
    }
}
