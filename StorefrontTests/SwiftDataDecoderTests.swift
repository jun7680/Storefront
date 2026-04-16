import XCTest
@testable import Storefront

final class SwiftDataDecoderTests: XCTestCase {
    func testNormalizeTableName() {
        XCTAssertEqual(SwiftDataDecoder.normalize(tableName: "ZTASK"), "Task")
        XCTAssertEqual(SwiftDataDecoder.normalize(tableName: "ZUSER"), "User")
        XCTAssertEqual(SwiftDataDecoder.normalize(tableName: "ZCALENDAREVENT"), "Calendarevent")
        XCTAssertEqual(SwiftDataDecoder.normalize(tableName: "users"), "users")
        XCTAssertEqual(SwiftDataDecoder.normalize(tableName: "Z"), "Z")
    }

    func testNormalizeColumnName() {
        XCTAssertEqual(SwiftDataDecoder.normalize(columnName: "ZNAME"), "name")
        XCTAssertEqual(SwiftDataDecoder.normalize(columnName: "ZCREATEDAT"), "createdat")
        XCTAssertEqual(SwiftDataDecoder.normalize(columnName: "ZcreatedAt"), "createdAt")
        XCTAssertEqual(SwiftDataDecoder.normalize(columnName: "Z_PK"), "Z_PK")
        XCTAssertEqual(SwiftDataDecoder.normalize(columnName: "Z_ENT"), "Z_ENT")
        XCTAssertEqual(SwiftDataDecoder.normalize(columnName: "regular"), "regular")
    }

    func testClassifyTableName() {
        XCTAssertEqual(
            SwiftDataDetector.classify(tableName: "ZTASK", kind: .swiftData),
            .swiftDataEntity
        )
        XCTAssertEqual(
            SwiftDataDetector.classify(tableName: "Z_METADATA", kind: .swiftData),
            .swiftDataSystem
        )
        XCTAssertEqual(
            SwiftDataDetector.classify(tableName: "Z_PRIMARYKEY", kind: .swiftData),
            .swiftDataSystem
        )
        XCTAssertEqual(
            SwiftDataDetector.classify(tableName: "users", kind: .swiftData),
            .standard
        )
        XCTAssertEqual(
            SwiftDataDetector.classify(tableName: "ZTASK", kind: .standard),
            .standard
        )
    }
}
