import GSLApi
import Foundation

public extension gsl_vector_view {
  public var array: [Double] {
    guard self.vector.size > 0 else { return [] }
    var v: [Double] = []
    var u = self.vector
    for i in 0 ..< self.vector.size {
      let x = gsl_vector_get(&u, i)
      v.append(x)
    }
    return v
  }
}

open class GSLMatrix: Equatable, CustomStringConvertible {

  let reference: UnsafeMutablePointer<gsl_matrix>

  public static func += (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    _ = gsl_matrix_add(m.reference, n.reference)
    return m
  }

  public static func + (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    let p = m.copy
    return p += n
  }

  public static func += (m: GSLMatrix, x: Double) -> GSLMatrix {
    _ = gsl_matrix_add_constant(m.reference, x)
    return m
  }

  public static func + (m: GSLMatrix, x: Double) -> GSLMatrix {
    let n = m.copy
    return n += x
  }

  public static func + (x: Double, m: GSLMatrix) -> GSLMatrix {
    return m + x
  }

  public static func -= (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    _ = gsl_matrix_sub(m.reference, n.reference)
    return m
  }

  public static func - (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    let p = m.copy
    return p -= n
  }

  public static func -= (m: GSLMatrix, x: Double) -> GSLMatrix {
    return m += (-x)
  }

  public static func - (m: GSLMatrix, x: Double) -> GSLMatrix {
    return m + (-x)
  }

  public static func - (x:Double, m: GSLMatrix) -> GSLMatrix {
    return x + (-1.0 * m)
  }

  public static func *= (m: GSLMatrix, x: Double) -> GSLMatrix {
    _ = gsl_matrix_scale(m.reference, x)
    return m
  }

  public static func * (m: GSLMatrix, x: Double) -> GSLMatrix {
    let n = m.copy
    return n *= x
  }

  public static func * (x: Double, m: GSLMatrix) -> GSLMatrix {
    return m * x
  }

  public static func *= (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    _ = gsl_matrix_mul_elements(m.reference, n.reference)
    return m
  }

  public static func * (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    let p = m.copy
    return p *= n
  }

  public static func /= (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    _ = gsl_matrix_div_elements(m.reference, n.reference)
    return m
  }

  public static func / (m: GSLMatrix, n: GSLMatrix) -> GSLMatrix {
    let p = m.copy
    return p /= n
  }

  public static func == (m: GSLMatrix, n: GSLMatrix) -> Bool {
    return 0 != gsl_matrix_equal(m.reference, n.reference)
  }

  public static func Swap(_ m: GSLMatrix, _ n: GSLMatrix) -> Int {
    return Int(gsl_matrix_swap(m.reference, n.reference))
  }

  public var diagonal: [Double] {
    let a = gsl_matrix_diagonal(reference)
    return a.array
  }

  public var rows : Int {
    return self.reference.pointee.size1
  }

  public var columns: Int {
    return self.reference.pointee.size2
  }

  public init (array: [[Double]]) throws {
    guard array.count > 0,
      array[0].count > 0
    else { throw GSLErrors.InvalidShape }

    reference = gsl_matrix_alloc(array.count, array[0].count)
    for i in 0 ..< self.rows {
      for j in 0 ..< self.columns {
        self.set(i, j, value: array[i][j])
      }
    }
  }

  public var copy: GSLMatrix {
    let c = GSLMatrix(rows: self.rows, columns: self.columns)
    _ = gsl_matrix_memcpy(c.reference, self.reference)
    return c
  }

  public var value: [[Double]] {
    var v:[[Double]] = []
    for i in 0 ..< self.rows {
      var u:[Double] = []
      for j in 0 ..< self.columns {
        u.append(self.get(i, j))
      }
      v.append(u)
    }
    return v
  }

  public init(rows: Int, columns: Int, data: String? = nil) {
    reference = gsl_matrix_calloc(rows, columns)
    guard let dat = data else { return }
    var fnumbers:[Int32] = [0, 0]
    guard 0 == pipe(&fnumbers),
      let fr = fdopen(fnumbers[0], "r"),
      let fw = fdopen(fnumbers[1], "w")
      else {
        return
    }
    defer {
      fclose(fr)
    }
    let written = dat.withCString { ptr -> Int in
      return fwrite(ptr, 1, dat.characters.count, fw)
    }
    fclose(fw)
    guard written > 0 else { return }
    _ = gsl_matrix_fscanf(fr, reference)
  }

  public var description: String {
    var fnumbers:[Int32] = [0, 0]
    guard 0 == pipe(&fnumbers),
      let fr = fdopen(fnumbers[0], "r"),
      let fw = fdopen(fnumbers[1], "w")
      else {
      return "{\"error\": \"streaming failed\"}"
    }
    gsl_matrix_fprintf(fw, reference, "%g")
    fclose(fw)
    var dataString = ""
    let szbuf = 4096
    var buf = UnsafeMutablePointer<CChar>.allocate(capacity: szbuf)
    defer {
      fclose(fr)
      buf.deallocate(capacity: szbuf)
    }
    while 0 == feof(fr) {
      memset(buf, 0, szbuf)
      let sz = fread(buf, 1, szbuf - 1, fr)
      if sz < 1 { break }
      dataString.append(String(cString: buf))
    }
    return dataString
  }

  public func `export`(stream: UnsafeMutablePointer<FILE>) throws {
    guard 0 == gsl_matrix_fwrite(stream, reference) else {
      throw GSLErrors.InvalidFilePointer
    }
  }

  public func `import`(stream: UnsafeMutablePointer<FILE>) throws {
    guard 0 == gsl_matrix_fread(stream, reference) else {
      throw GSLErrors.InvalidFilePointer
    }
  }

  public func `export`(path: String) throws {
    guard let f = fopen(path, "wb") else {
      throw GSLErrors.InvalidFilePointer
    }
    defer {
      fclose(f)
    }
    try self.export(stream: f)
  }

  public func `import`(path: String) throws {
    guard let f = fopen(path, "rb") else {
      throw GSLErrors.InvalidFilePointer
    }
    defer {
      fclose(f)
    }
    try self.import(stream: f)
  }

  public func `get`(_ i: Int, _ j: Int) -> Double {
    return gsl_matrix_get(reference, i, j)
  }

  public func `set`(_ i: Int, _ j: Int, value: Double) {
      gsl_matrix_set(reference, i, j, value)
  }

  public func setAllElements(toValue: Double = 0) {
    if toValue == 0 {
      gsl_matrix_set_zero(reference)
    } else {
      gsl_matrix_set_all(reference, toValue)
    }
  }

  public func setToIdentity() {
    gsl_matrix_set_identity(reference)
  }

  public var isNull: Bool {
    return gsl_matrix_isnull(reference) > 0
  }

  public var isPos: Bool {
    return gsl_matrix_ispos(reference) > 0
  }

  public var isNeg: Bool {
    return gsl_matrix_isneg(reference) > 0
  }

  public var isNonneg: Bool {
    return gsl_matrix_isnonneg(reference) > 0
  }

  deinit {
    gsl_matrix_free(reference)
  }
}
