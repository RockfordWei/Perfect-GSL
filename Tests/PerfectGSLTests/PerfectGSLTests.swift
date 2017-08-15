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

  func testInitV() {
    let v = GSLVector(size: 3)
    XCTAssertTrue(v.isNull)
    XCTAssertTrue(v.isNonneg)
    XCTAssertFalse(v.isNeg)
    XCTAssertFalse(v.isPos)
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

  func testGetSetV() {
    let v = GSLVector(size: 6)
    for j in 0 ..< v.size {
      v.set(j, value: Double(j))
    }
    for (i, w) in v.value.enumerated() {
      XCTAssertEqual(i, Int(w))
    }
  }

  func testStringsV() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let v = GSLVector(size: 6, data: x)
    let y = v.description
    XCTAssertEqual(x, y)
    let w = GSLVector(size: 6, data: y)
    XCTAssertEqual(v, w)
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

  func testExportImportV() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let v = GSLVector(size: 6, data: x)
    let w = GSLVector(size: 6)
    let tmp = "/tmp/gslvector.dat"
    do {
      try v.export(path: tmp)
      try w.import(path: tmp)
      XCTAssertEqual(v, w)
      XCTAssertEqual(x, w.description)
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

  func testBasis() {
    let a = GSLVector(size: 256)
    a.setAllElements(toValue: 2)
    let b = GSLVector(size: 256)
    b.setAllElements()
    b.set(128, value: 1)
    _ = a.setBasis(128)
    XCTAssertEqual(a, b)
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

  func testSwapV() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let y = "0\n2\n4\n6\n8\n10\n"
    let v = GSLVector(size: 6, data: x)
    let w = GSLVector(size: 6, data: y)
    GSLVector.Swap(v: v, w: w)
    XCTAssertEqual(x, w.description)
    XCTAssertEqual(y, v.description)
  }

  func testComputationV() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let v = GSLVector(size: 6, data: x)
    let w = v * 2
    let u = v + v
    let y = v * u
    for (i, j) in y.value.enumerated() {
      XCTAssertEqual(i * (i * 2), Int(j))
    }

    let z = y / u
    XCTAssertEqual(u, w)
    var m = v.value
    m.remove(at: 0)
    var n = z.value
    n.remove(at: 0)
    XCTAssertEqual(m, n)
  }

  func testComputation() {
    let x = "0\n1\n2\n3\n4\n5\n"
    let m = GSLMatrix(rows: 2, columns: 3, data: x)
    let m2 = m * 2
    XCTAssertEqual(m2.description, "0\n2\n4\n6\n8\n10\n")
    let m3 = m2 - m
    XCTAssertEqual(m3, m)
    XCTAssertEqual(m3 + m, m2)
    let m4 = GSLMatrix(rows: 3, columns: 3)
    m4.setAllElements(toValue: 2.0)
    let m5 = GSLMatrix(rows: 3, columns: 3)
    m5.setToIdentity()
    let m6 = m4 * m5
    let m7 = m5 * 2
    XCTAssertEqual(m6, m7)
    let m8 = m7 / m5
    XCTAssertEqual(m7.diagonal, m8.diagonal)
  }

  static var allTests = [
    ("testInit", testInit),
    ("testInitV", testInitV),
    ("testGetSet", testGetSet),
    ("testGetSetV", testGetSetV),
    ("testStrings", testStrings),
    ("testStringsV", testStringsV),
    ("testConvertion", testConvertion),
    ("testIdentity", testIdentity),
    ("testBasis", testBasis),
    ("testSwap", testSwap),
    ("testSwapV", testSwapV),
    ("testComputation", testComputation),
    ("testComputationV", testComputationV),
    ("testExportImportV", testExportImportV),
    ("testExportImport", testExportImport)
    ]
}
