import GSLApi
import Foundation

public enum GSLErrors: Error {
  case InvalidFilePointer
}

open class GSLMatrix: Equatable, CustomStringConvertible {

  let reference: UnsafeMutablePointer<gsl_matrix>

  public static func == (m: GSLMatrix, n: GSLMatrix) -> Bool {
    return 0 != gsl_matrix_equal(m.reference, n.reference)
  }

  public var rows : Int {
    return self.reference.pointee.size1
  }

  public var columns: Int {
    return self.reference.pointee.size2
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
