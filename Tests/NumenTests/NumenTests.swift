import XCTest
@testable import Numen

final class NumenTests: XCTestCase {
    func testFieldParsing() throws {
        let fields = Field.parseFields("name:String,email:String,age:Int?")
        XCTAssertEqual(fields.count, 3)
        XCTAssertEqual(fields[0].name, "name")
        XCTAssertEqual(fields[0].swiftType, "String")
        XCTAssertFalse(fields[0].optional)
        XCTAssertEqual(fields[1].name, "email")
        XCTAssertEqual(fields[2].name, "age")
        XCTAssertTrue(fields[2].optional)
    }

    func testFieldParsingEmptyString() {
        let fields = Field.parseFields(nil)
        XCTAssertTrue(fields.isEmpty)
    }

    func testSwiftTypeMapping() {
        XCTAssertEqual(Field(name: "x", type: "string").swiftType, "String")
        XCTAssertEqual(Field(name: "x", type: "int").swiftType, "Int")
        XCTAssertEqual(Field(name: "x", type: "bool").swiftType, "Bool")
        XCTAssertEqual(Field(name: "x", type: "date").swiftType, "Date")
    }
}
