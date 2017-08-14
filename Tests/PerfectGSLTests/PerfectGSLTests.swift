import XCTest
@testable import PerfectGSL

class PerfectGSLTests: XCTestCase {
  func testInit() {
    let m = GSLMatrix(rows: 2, columns: 3)
    XCTAssertTrue(m.isNull)
    XCTAssertTrue(m.isNonneg)
    XCTAssertFalse(m.isNeg)
    XCTAssertFalse(m.isPos)
  }

  func testGetSet() {
    let m = GSLMatrix(rows: 2, columns: 3)
    for i in 0 ..< 2 {
      for j in 0 ..< 3 {
        let x = i * 3 + j
        print(i, j, x)
        m.set(i, j, value: Double(x))
        let y = Int(m.get(i, j))
        XCTAssertEqual(x, y)
      }
    }
  }

  func testStrings() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let m = GSLMatrix(rows: 2, columns: 3, data: x)
    let y = m.description
    XCTAssertEqual(x, y)
    let n = GSLMatrix(rows: 2, columns: 3, data: y)
    XCTAssertEqual(m, n)
  }

  func testExportImport() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let m = GSLMatrix(rows: 2, columns: 3, data: x)
    let n = GSLMatrix(rows: 2, columns: 3)
    XCTAssertEqual(m.rows, n.rows)
    XCTAssertEqual(m.columns, n.columns)
    let tmp = "/tmp/gslmatrix.dat"
    do {
      try m.export(path: tmp)
      try n.import(path: tmp)
      XCTAssertEqual(m, n)
      XCTAssertEqual(x, n.description)
    }catch {
      XCTFail(error.localizedDescription)
    }
  }

  static var allTests = [
    ("testInit", testInit),
    ("testGetSet", testGetSet),
    ("testStrings", testStrings),
    ("testExportImport", testExportImport)
    ]
}
