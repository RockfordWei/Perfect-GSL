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

  func testConvertion() {
    let a:[[Double]] = [[0,1,2],[3,4,5]]
    do {
      let m = try GSLMatrix(array: a)
      let b = m.value
      for i in 0 ..< 2 {
        let x = a[i]
        let y = b[i]
        XCTAssertEqual(x, y)
      }
    }catch {
      XCTFail(error.localizedDescription)
    }
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

  func testIdentity() {
    let sz = 128
    let m = GSLMatrix(rows: sz, columns: sz)
    m.setAllElements()
    m.setToIdentity()
    for i in 0..<sz {
      for j in 0..<sz {
        let n = m.get(i, j)
        if i == j {
          XCTAssertEqual(n, 1)
        } else {
          XCTAssertEqual(n, 0)
        }
      }
    }
  }

  func testSwap() {
    let sz = 128
    let m = GSLMatrix(rows: sz, columns: sz)
    let n = GSLMatrix(rows: sz, columns: sz)
    m.setAllElements(toValue: 1)
    n.setAllElements(toValue: 2)
    _ = GSLMatrix.Swap(m, n)
    for i in 0 ..< sz {
      for j in 0 ..< sz {
        XCTAssertEqual(m.get(i, j), 2)
        XCTAssertEqual(n.get(i, j), 1)
      }
    }
  }
  static var allTests = [
    ("testInit", testInit),
    ("testGetSet", testGetSet),
    ("testStrings", testStrings),
    ("testConvertion", testConvertion),
    ("testIdentity", testIdentity),
    ("testSwap", testSwap),
    ("testExportImport", testExportImport)
    ]
}
